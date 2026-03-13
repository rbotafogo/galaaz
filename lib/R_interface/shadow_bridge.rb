# shadow_bridge.rb
#
# Bridge to a long-lived R process. Communicates via:
#   - stdin/stdout: R code is sourced from temp scripts; R prints markers (--G_END--, --G_CALLBACK--, etc.)
#   - RESULT_FIFO: R writes one length-prefixed binary envelope per galaaz_result() call (scalars or handle names)
#   - CALLBACK_FIFO: when R invokes a Ruby proc, it blocks reading this FIFO; we send --G_CMD-- or --G_RET--
#
# Two evaluation modes:
#   - eval_r(code): send code, wait for --G_END--, return stdout (no result envelope). Callbacks supported.
#   - eval_r_with_result(assignment): send "var <- expr; galaaz_result(var)", wait for --G_END--, read one envelope from RESULT_FIFO.
#
# When a Ruby proc is invoked from R (e.g. in outer()), we set @in_callback. Nested eval_r / eval_r_with_result
# then send commands via CALLBACK_FIFO and consume --G_CMD_END-- from stdout; for eval_r_with_result we read
# from RESULT_FIFO (shared fd if outer was eval_r_with_result, else open O_RDWR before sending to avoid deadlock).
#
require 'open3'
require 'java'
require 'singleton'
require 'fileutils'
require 'fcntl'
require 'monitor'

# Load Arrow JARs before importing
Dir.glob("/home/rbotafogo/arrow_jars/*.jar").each { |jar| require jar }

java_import 'java.io.RandomAccessFile'
java_import 'java.nio.channels.FileChannel'
java_import 'java.nio.ByteOrder'

java_import 'java.io.FileInputStream'
java_import 'org.apache.arrow.memory.RootAllocator'
java_import 'org.apache.arrow.vector.ipc.ArrowFileReader'

module R
  class ShadowBridge
    include Singleton
    attr_reader :last_envelope_nil_reason

    # Paths under /dev/shm for process communication
    DATA_FILE = "/dev/shm/galaaz_data"           # binary bulk transfer (vectors)
    SYNC_FILE = "/dev/shm/galaaz_sync"          # sync marker written when bridge is ready
    RESULT_BUFFER = "/dev/shm/galaaz_result"    # deprecated; use RESULT_FIFO
    RESULT_FIFO = "/dev/shm/galaaz_result_fifo" # R writes one envelope per galaaz_result() call
    CMD_SCRIPT_BASE = "/dev/shm/galaaz_cmd"     # temp R scripts: CMD_SCRIPT_BASE_<seq>.R
    CALLBACK_FIFO = "/dev/shm/galaaz_callback_fifo" # R reads --G_CMD-- / --G_RET-- when in a Ruby callback

    # Log files: use absolute path so they work when process chdirs (e.g. gknit to Rmd dir).
    # From lib/R_interface/ go up to project/gem root, then logs/
    LOG_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'logs'))

    def initialize
      puts "DEBUG: Initializing ShadowBridge instance #{self.object_id}" if ENV['GALAAZ_DEBUG']
      FileUtils.mkdir_p(LOG_DIR) unless Dir.exist?(LOG_DIR)
      @bridge_ready = false
      @in_callback = false
      @last_sent_code = nil
      @command_seq = 0
      @script_seq = 0
      @bridge_mutex = Monitor.new  # re-entrant: callback can call bridge again
      @eval_r_with_result_depth = 0
      @result_fifo_io = nil
      @last_envelope_nil_reason = nil
      @allocator = RootAllocator.new
      @callback_seq = 0  # Sequence counter for callback command/response matching

      setup_fifos
      start_r_process
      setup_r_environment
      File.write(SYNC_FILE, [0].pack("N"))
      @bridge_ready = true
    end

    # Create FIFOs if they don't exist (callback channel and result envelope channel).
    def setup_fifos
      system("mkfifo #{CALLBACK_FIFO}") unless File.exist?(CALLBACK_FIFO)
      system("mkfifo #{RESULT_FIFO}") unless File.exist?(RESULT_FIFO)
    end

    # Start the R subprocess and a thread that logs its stderr.
    # When GALAAZ_DEBUG_R=1, set GALAAZ_R_RECEIVED_LOG so R can log each command it receives in the callback (for matching Ruby send vs R receive).
    def start_r_process
      env = ENV.to_h
      if ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true"
        env["GALAAZ_R_RECEIVED_LOG"] = File.expand_path(log_path("galaaz_r_received.log"))
      end
      @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(env, "R --vanilla --quiet --slave")
      if ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true"
        r_pid = @wait_thr.pid rescue nil
        File.write(log_path("galaaz_r_pid.txt"), "R process PID: #{r_pid}\n") if r_pid
      end
      Thread.new do
        while line = @stderr.gets
          File.open(log_path("galaaz_r_stderr.log"), "a") { |f| f.puts "[R STDERR] #{line}" }
        end
      end
    end

    # Read one line from R stdout; when GALAAZ_DEBUG_R=1, tee to galaaz_r_stdout.log only (not console; use logs for full R output).
    def read_stdout_line
      line = @stdout.gets
      if line && (ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true")
        File.open(log_path("galaaz_r_stdout.log"), "a") { |f| f.write(line) }
      end
      line
    end

    def log_path(basename)
      File.join(LOG_DIR, basename)
    end

    # Log a point where we might block (for hang diagnosis). Always written and flushed.
    def log_hang_point(label)
      path = log_path("galaaz_r_debug.log")
      ts = Time.now.strftime("%H:%M:%S.%L")
      File.open(path, "a") { |f| f.puts "[#{ts}][HANG_POINT] #{label}"; f.flush }
    end

    # Load R libraries, define capture2/missing_arg, inject galaaz_result, set lib path.
    def setup_r_environment
      eval_r("library(R.utils)")
      eval_r("library(arrow)")
      eval_r("library(rlang)")
      eval_r("missing_arg <- function() { quote(f(,0))[[2]] }")
      eval_r("capture2 <- function(obj, ...) { f <- tempfile(); on.exit(unlink(f), add=FALSE); con <- NULL; on.exit({ if (!is.null(con)) close(con) }, add=TRUE); con <- file(f, 'wt'); sink(con, type='output'); print(obj, ...); sink(); close(con); con <- NULL; readLines(f) }")
      define_galaaz_result
      eval_r("awt <- function(...) { X11(...) }")
      lib_dir = File.expand_path("~/R/x86_64-pc-linux-gnu-library/galaaz")
      FileUtils.mkdir_p(lib_dir) unless Dir.exist?(lib_dir)
      eval_r(".libPaths(c('#{lib_dir}', .libPaths()))")
      eval_r("library(evaluate)")
      galaaz_device_path = File.expand_path(File.join(File.dirname(__FILE__), 'galaaz_device.R'))
      eval_r("source('#{galaaz_device_path.gsub("'", "\\\\'")}')")
    end

    # Define in R the galaaz_result() function that writes one length-prefixed envelope to RESULT_FIFO.
    def define_galaaz_result
      eval_r(<<~GALAAZ_RESULT)
        galaaz_result <- function(x, var_name) {
          path <- "#{RESULT_FIFO}"
          dbg <- Sys.getenv('GALAAZ_DEBUG_R', '') == '1'
          if (dbg) cat('[G_RESULT]', 'start', var_name, '\\n')
          r_type <- typeof(x)
          r_len <- length(x)
          r_class <- paste(class(x), collapse = " ")
          type_code <- 4L
          len <- 0L
          payload <- raw(0)
          rc <- NULL
          on.exit({ if (!is.null(rc)) close(rc) }, add = FALSE)
          if (r_len == 1 && r_type == "double") {
            type_code <- 0L
            len <- 1L
            rc <- rawConnection(raw(0), "wb")
            writeBin(as.double(x), rc, size = 8, endian = "little")
            payload <- rawConnectionValue(rc)
            close(rc)
            rc <- NULL
          } else if (r_len == 1 && r_type == "integer") {
            type_code <- 1L
            len <- 1L
            rc <- rawConnection(raw(0), "wb")
            writeBin(as.integer(x), rc, size = 4, endian = "little")
            payload <- rawConnectionValue(rc)
            close(rc)
            rc <- NULL
          } else if (r_len == 1 && r_type == "logical") {
            type_code <- 2L
            len <- 1L
            b <- if (is.na(x)) 2L else (if (x) 1L else 0L)
            payload <- as.raw(b)
          } else if (r_len == 1 && r_type == "character") {
            type_code <- 3L
            len <- 1L
            s <- enc2utf8(as.character(x))
            rc <- rawConnection(raw(0), "wb")
            writeBin(as.integer(nchar(s, type = "bytes")), rc, size = 4, endian = "little")
            writeBin(charToRaw(s), rc)
            payload <- rawConnectionValue(rc)
            close(rc)
            rc <- NULL
          } else if (r_type == "symbol" || r_type == "name") {
            type_code <- 4L
            len <- 0L
            h <- enc2utf8(as.character(var_name))
            rc <- rawConnection(raw(0), "wb")
            writeBin(as.integer(nchar(h, type = "bytes")), rc, size = 4, endian = "little")
            writeBin(charToRaw(h), rc)
            writeBin(as.integer(nchar(r_class, type = "bytes")), rc, size = 4, endian = "little")
            writeBin(charToRaw(r_class), rc)
            payload <- rawConnectionValue(rc)
            close(rc)
            rc <- NULL
          } else {
            type_code <- 4L
            len <- 0L
            h <- enc2utf8(as.character(var_name))
            rc <- rawConnection(raw(0), "wb")
            writeBin(as.integer(nchar(h, type = "bytes")), rc, size = 4, endian = "little")
            writeBin(charToRaw(h), rc)
            writeBin(as.integer(nchar(r_class, type = "bytes")), rc, size = 4, endian = "little")
            writeBin(charToRaw(r_class), rc)
            payload <- rawConnectionValue(rc)
            close(rc)
            rc <- NULL
          }
          if (dbg) cat('[G_RESULT]', 'payload done, type=', type_code, '\\n')
          envelope_rc <- NULL
          out <- NULL
          on.exit({
            if (!is.null(envelope_rc)) close(envelope_rc)
            if (!is.null(out)) close(out)
          }, add = TRUE)
          envelope_rc <- rawConnection(raw(0), "wb")
          writeBin(as.raw(type_code), envelope_rc)
          writeBin(as.integer(len), envelope_rc, size = 4, endian = "little")
          writeBin(payload, envelope_rc)
          envelope <- rawConnectionValue(envelope_rc)
          close(envelope_rc)
          envelope_rc <- NULL
          total_len <- as.integer(4 + length(envelope))
          if (dbg) cat('[G_RESULT]', 'opening file', path, '\\n')
          out <- file(path, "wb")
          if (dbg) cat('[G_RESULT]', 'writing', total_len, 'bytes\\n')
          writeBin(total_len, out, size = 4, endian = "little")
          writeBin(envelope, out)
          close(out)
          out <- NULL
          if (dbg) cat('[G_RESULT]', 'done\\n')
          invisible(NULL)
        }
      GALAAZ_RESULT
    end

    def ready?
      @bridge_ready
    end

    def in_callback?
      @in_callback
    end

    # Append one line to galaaz_trace.log when GALAAZ_TRACE=1 (for debugging "R process is dead").
    def trace_log(method, code)
      @command_seq += 1
      File.open(log_path("galaaz_trace.log"), "a") { |f| f.puts "[#{@command_seq}] #{method}: #{code.to_s.strip[0..500]}#{'...' if code.to_s.length > 500}" }
    end

    # When GALAAZ_DEBUG_R=1, log every R script we send to galaaz_r_scripts.log (full content, sequential).
    def log_r_script_if_debug(label, script_content)
      return unless ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true"
      ts = Time.now.strftime("%Y-%m-%d %H:%M:%S.%L")
      @script_seq ||= 0
      File.open(log_path("galaaz_r_scripts.log"), "a") do |f|
        f.puts ""
        f.puts "========== #{ts} seq=#{@script_seq} #{label} =========="
        f.puts script_content
        f.puts "========== end #{label} =========="
      end
    end

    # When GALAAZ_DEBUG_R=1, print to stderr so console shows Ruby/R traffic in execution order.
    def debug_r_console(tag, msg)
      return unless ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true"
      $stderr.puts "[#{tag}] #{msg}"
      $stderr.flush
    end

    # When GALAAZ_DEBUG_R or GALAAZ_DEBUG_OBJECT is set, ask R to write class/typeof/str of the
    # object with the given handle to logs/galaaz_obj_debug.txt (and cat to stdout). Use before
    # is_field check to see what object triggers "invalid connection".
    # GALAAZ_DEBUG_OBJECT=g2_v873: dump only that handle (even if --debugR is on). GALAAZ_DEBUG_OBJECT=1 or true: dump every handle.
    def log_connections_in_r
      return unless ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true"
      begin
        eval_r("cat('[CONNECTIONS]', length(getAllConnections()), 'active connections\\n')")
      rescue
        # Ignore errors
      end
    end

    def log_object_in_r(handle)
      do_env = ENV["GALAAZ_DEBUG_OBJECT"].to_s
      if do_env != "" && do_env != "0" && do_env != "false"
        # Specific handle requested: only dump that handle
        return unless do_env == "1" || do_env == "true" || do_env == handle.to_s
      else
        # No DEBUG_OBJECT; only dump all when DEBUG_R is on
        return unless ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true"
      end
      handle_esc = handle.to_s.gsub("'", "\\\\'")
      out_path = log_path("galaaz_obj_debug.txt").gsub("\\", "\\\\").gsub("'", "\\\\'")
      # Use simple print/sink instead of capture.output to avoid textConnection issues
      code = <<~R.strip
        tryCatch({
          o <- get('#{handle_esc}', envir=.GlobalEnv);
          cat('[OBJECT_DEBUG]', '#{handle_esc}', 'class:', paste(class(o), collapse=','), 'typeof:', typeof(o), 'dim:', paste(dim(o), collapse='x'), '\\n');
          # Simple output without capture.output to avoid textConnection
          out_con <- file('#{out_path}', 'at')
          on.exit(close(out_con), add = FALSE)
          writeLines(paste('#{handle_esc} summary:'), out_con)
          writeLines(paste('  class:', paste(class(o), collapse=',')), out_con)
          writeLines(paste('  typeof:', typeof(o)), out_con)
          writeLines(paste('  dim:', paste(dim(o), collapse='x')), out_con)
          writeLines(paste('  length:', length(o)), out_con)
          close(out_con)
          on.exit(NULL, add = FALSE)
        }, error=function(e) { cat('[OBJECT_DEBUG]', '#{handle_esc}', 'error:', conditionMessage(e), '\\n') })
      R
      eval_r(code)
    end

    # Evaluate R code. No result envelope; returns stdout (or from callback path, output until --G_CMD_END--).
    # When @in_callback, sends code via CALLBACK_FIFO and reads stdout until --G_CMD_END--.
    def eval_r(code)
      puts "DEBUG: R.eval_r(#{code.inspect})" if ENV['GALAAZ_DEBUG']
      code = code.to_s
      return eval_r_in_callback(code) if @in_callback
      @bridge_mutex.synchronize { eval_r_top_level(code) }
    end

    # Send code to R via CALLBACK_FIFO; read stdout until --G_CMD_END--, 
    #handling nested --G_CALLBACK-- and --G_ERR--.
    def eval_r_in_callback(code)
      ts = Time.now.strftime("%H:%M:%S.%L")
      @callback_seq += 1
      seq = @callback_seq
      File.open(log_path("galaaz_r_debug.log"), "a") { |f| f.puts "[#{ts}][JRuby Nested] seq=#{seq} #{code}" }
      payload = "--G_CMD--seq=#{seq}--#{code.gsub("\n", "\\n")}\n"
      if ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true"
        File.open(log_path("galaaz_r_debug.log"), "a") { |f| f.puts "[#{ts}][RUBY_SEND_EXACT] #{payload.inspect}" }
      end
      File.write(CALLBACK_FIFO, payload)
      debug_r_console("RUBY", "callback seq=#{seq}: #{code.strip[0..200]}#{'...' if code.length > 200}")
      log_hang_point("eval_r_in_callback seq=#{seq}: waiting for stdout until --G_CMD_END--")
      output = ""
      while line = read_stdout_line
        File.open(log_path("galaaz_r_debug.log"), "a") { |f| f.puts "[#{ts}][R stdout Nested] #{line}" }
        if line.start_with?('--G_CALLBACK--')
          process_callback(line)
          next
        end
        if line.start_with?('--G_ERR--')
          raise "R Error (Nested): #{line.sub('--G_ERR--', '').strip}\nCode: seq=#{seq} #{code}"
        end
        # Check for matching sequence number in --G_CMD_END--
        if line =~ /--G_CMD_END--seq=#{seq}--/
          break
        end
        # Also break on legacy --G_CMD_END-- for backward compatibility
        if line.include?('--G_CMD_END--') && !line.include?('seq=')
          File.open(log_path("galaaz_r_debug.log"), "a") { |f| f.puts "[#{ts}][SEQ_MISMATCH] Expected seq=#{seq}, got legacy --G_CMD_END--" }
          break
        end
        output << line unless line.start_with?('--G_')
      end
      output.strip
    end

    # Build the R expression to run: normalize g2_v assignments to .GlobalEnv$var, wrap rest in print({...}).
    def build_eval_r_cmd(code)
      stripped = code.strip
      return "NULL" if stripped.empty?
      if stripped =~ /^(\w+) <- (.*)$/m
        var, expr = $1, $2
        return (var.start_with?("g2_v") && !var.include?("$")) ? ".GlobalEnv$#{var} <- #{expr}" : code
      end
      return code if stripped.include?("assign(")
      "print({#{code}\n})"
    end

    # Write tryCatch script to temp file, source it in R, read stdout until --G_END--. 
    # Handles --G_CALLBACK-- and --G_ERR--.
    def eval_r_top_level(code)
      ts = Time.now.strftime("%H:%M:%S.%L")
      File.open(log_path("galaaz_r_debug.log"), "a") { |f| f.puts "[#{ts}][JRuby] #{code.lines.first.strip}#{'...' if code.lines.size > 1}" }
      r_cmd = build_eval_r_cmd(code)
      @script_seq += 1
      tmp_r = "#{CMD_SCRIPT_BASE}_#{@script_seq}.R"
      script_content = <<~R
        tryCatch({
          #{r_cmd}
        }, error = function(e) {
          msg <- conditionMessage(e)
          tb <- paste(capture.output(traceback()), collapse = "\\n")
          cat('--G_ERR--', msg, '\\n', sep='')
          if (nchar(tb) > 0) cat('--G_TRACE--', tb, '\\n', sep='')
        }, finally = {
          cat('--G_END--\\n')
        })
      R
      File.write(tmp_r, script_content)
      log_r_script_if_debug("eval_r", script_content)
      raise "R process is dead. Cannot evaluate code.\nLast command (eval_r): #{@last_sent_code.inspect}" unless @wait_thr.alive?
      @last_sent_code = code
      trace_log("eval_r", code) if ENV["GALAAZ_TRACE"]
      debug_r_console("RUBY", "top-level: #{code.lines.first.to_s.strip[0..150]}#{'...' if code.lines.size > 1}")
      @stdin.puts("source('#{tmp_r}')")
      @stdin.flush
      read_stdout_until_g_end(code)
    end

    # Read @stdout until --G_END--; handle --G_CALLBACK-- (process_callback) and --G_ERR-- 
    # (drain then raise). Return collected output.
    def read_stdout_until_g_end(code)
      output = ""
      while line = read_stdout_line
        raise "R process died (stdout EOF). Last command (eval_r): #{@last_sent_code.inspect}" if line.nil?
        ts = Time.now.strftime("%H:%M:%S.%L")
        File.open(log_path("galaaz_r_debug.log"), "a") { |f| f.puts "[#{ts}][R stdout] #{line}" }
        if line.start_with?('--G_CALLBACK--')
          process_callback(line)
          next
        end
        if line.start_with?('--G_ERR--')
          error_msg = line.sub('--G_ERR--', '').strip
          trace_line = read_stdout_line
          trace_msg = (trace_line && trace_line.start_with?('--G_TRACE--')) ? trace_line.sub('--G_TRACE--', '').strip.gsub("\\n", "\n") : nil
          while (drain = read_stdout_line)
            break if drain.strip == '--G_END--'
          end
          full_msg = "R Error: #{error_msg}"
          full_msg += "\nCode: #{code}" if code && !code.empty?
          full_msg += "\n--- R traceback ---\n#{trace_msg}" if trace_msg && !trace_msg.empty?
          raise full_msg
        end
        break if line.include?('--G_END--')
        output << line unless line.start_with?('--G_')
      end
      output.strip
    end

    # Read one length-prefixed envelope from an open FIFO or IO. Returns decoded hash (e.g. { type: :scalar_double, value: 1.0 }) or nil.
    # Sets @last_envelope_nil_reason on failure for diagnostics.
    def read_result_envelope_from_io(io)
      @last_envelope_nil_reason = nil
      return (@last_envelope_nil_reason = "io_nil"; nil) unless io
      raw_len = io.read(4)
      return (@last_envelope_nil_reason = "raw_len_nil_or_short"; nil) if raw_len.nil? || raw_len.bytesize < 4
      total_len = raw_len.unpack1("V")
      return (@last_envelope_nil_reason = "total_len_#{total_len}_lt_5"; nil) if total_len < 5
      envelope = io.read(total_len - 4)
      return (@last_envelope_nil_reason = "envelope_nil_or_short"; nil) if envelope.nil? || envelope.bytesize < total_len - 4
      result = parse_envelope_bytes(envelope)
      @last_envelope_nil_reason = "parse_nil_type_#{envelope.getbyte(0)}" if result.nil?
      result
    rescue => e
      @last_envelope_nil_reason = "rescue_#{e.class}_#{e.message[0..80]}"
      File.open(log_path("galaaz_r_debug.log"), "a") { |f| f.puts "[read_result_envelope_from_io] #{e.message}" }
      nil
    end

    # Interpret escape sequences in scalar character from R (literal \n, \t, etc. -> real chars).
    # Matches R's double-quoted string escapes. Order: two-char sequences first, \\ last.
    def unescape_scalar_character(str)
      str.gsub("\\n", "\n")
          .gsub("\\r", "\r")
          .gsub("\\t", "\t")
          .gsub("\\b", "\b")
          .gsub("\\a", "\a")
          .gsub("\\f", "\f")
          .gsub("\\v", "\v")
          .gsub("\\0", "\0")
          .gsub('\\"', '"')
          .gsub("\\'", "'")
          .gsub("\\\\", "\\")
    end

    # Decode envelope payload: type byte + length + payload. Returns hash with :type and :value or :handle/:r_class.
    def parse_envelope_bytes(envelope)
      return nil if envelope.bytesize < 5
      type_code = envelope.getbyte(0)
      len = envelope.byteslice(1, 4).unpack1("V")
      payload = envelope.byteslice(5..-1) || ""
      case type_code
      when 0 # scalar double
        return nil if payload.bytesize < 8
        { type: :scalar_double, value: payload.byteslice(0, 8).unpack1("E") }
      when 1 # scalar integer
        return nil if payload.bytesize < 4
        { type: :scalar_integer, value: payload.byteslice(0, 4).unpack1("l<") }
      when 2 # scalar logical
        return nil if payload.bytesize < 1
        b = payload.getbyte(0)
        val = (b == 2 ? R::NA : (b == 1))
        { type: :scalar_logical, value: val }
      when 3 # scalar character
        return nil if payload.bytesize < 4
        n = payload.byteslice(0, 4).unpack1("V")
        return nil if payload.bytesize < 4 + n
        str = payload.byteslice(4, n)
        str = str.force_encoding("UTF-8")
        str = unescape_scalar_character(str)
        { type: :scalar_character, value: str }
      when 4 # handle only
        return nil if payload.bytesize < 8
        handle_len = payload.byteslice(0, 4).unpack1("V")
        return nil if payload.bytesize < 4 + handle_len + 4
        handle = payload.byteslice(4, handle_len).force_encoding("UTF-8")
        class_len = payload.byteslice(4 + handle_len, 4).unpack1("V")
        return nil if payload.bytesize < 4 + handle_len + 4 + class_len
        r_class = payload.byteslice(4 + handle_len + 4, class_len).force_encoding("UTF-8").strip
        puts "DEBUG: parse_envelope_bytes type=handle handle=#{handle.inspect} r_class=#{r_class.inspect}" if ENV['GALAAZ_DEBUG']
        { type: :handle, handle: handle, r_class: r_class }
      when 5 # scalar symbol
        return nil if payload.bytesize < 4
        n = payload.byteslice(0, 4).unpack1("V")
        return nil if payload.bytesize < 4 + n
        name = payload.byteslice(4, n).force_encoding("UTF-8")
        sym = name.gsub("::", "___").gsub(".", "__").to_sym
        { type: :scalar_symbol, value: sym }
      else
        nil
      end
    end

    # Send "var <- expr; galaaz_result(var)" to R, wait for --G_END--, read one envelope from RESULT_FIFO.
    # Only accepts assignment_code of the form "g2_v* <- ..." or ".GlobalEnv$g2_v* <- ..."; returns nil otherwise.
    # When @in_callback: use callback-safe protocol (stdout-based) to avoid "invalid connection" errors
    def eval_r_with_result(assignment_code)
      r_cmd = build_eval_r_with_result_cmd(assignment_code)
      return nil unless r_cmd
      if @in_callback
        # In callback: use simple print-based approach instead of binary protocol
        # This avoids complex FIFO coordination that causes "invalid connection" errors
        return @bridge_mutex.synchronize { eval_r_with_result_in_callback_simple(r_cmd) }
      end
      @bridge_mutex.synchronize { eval_r_with_result_top_level(r_cmd) }
    end

    # Returns ".GlobalEnv$var <- expr; galaaz_result(.GlobalEnv$var, 'var')" if assignment_code matches g2_v* <- ..., else nil.
    def build_eval_r_with_result_cmd(assignment_code)
      stripped = assignment_code.strip
      m = stripped.match(/\A\.GlobalEnv\$(\w+) <- (.+)\z/m) || stripped.match(/\A(\w+) <- (.+)\z/m)
      unless m && m[1].start_with?("g2_v")
        puts "DEBUG: eval_r_with_result no match for assignment_code=#{assignment_code.inspect}" if ENV['GALAAZ_DEBUG']
        return nil
      end
      var, expr = m[1], m[2]
      ".GlobalEnv$#{var} <- #{expr}; galaaz_result(.GlobalEnv$#{var}, '#{var}')"
    end

    # Nested call from a Ruby callback: open RESULT_FIFO O_RDWR if no shared fd (avoids R blocking on write),
    # send r_cmd via CALLBACK_FIFO, read stdout until --G_CMD_END--, then read one envelope.
    def eval_r_with_result_in_callback(r_cmd)
      fifo_io = @result_fifo_io
      tmp_fifo = nil
      if fifo_io.nil?
        begin
          # Try to drain any stale data from RESULT_FIFO before opening
          begin
            stale_fd = File.open(RESULT_FIFO, File::RDONLY | Fcntl::O_NONBLOCK)
            stale_data = stale_fd.read(65536)
            stale_fd.close
            if stale_data && !stale_data.empty?
              File.open(log_path("galaaz_r_debug.log"), "a") { |f| f.puts "[#{Time.now.strftime('%H:%M:%S.%L')}] Drained #{stale_data.length} stale bytes from RESULT_FIFO" }
            end
          rescue
            # Ignore errors from draining attempt
          end
          
          tmp_fifo = File.open(RESULT_FIFO, File::RDWR | Fcntl::O_NONBLOCK)
          tmp_fifo.fcntl(Fcntl::F_SETFL, tmp_fifo.fcntl(Fcntl::F_GETFL) & ~Fcntl::O_NONBLOCK)
        rescue Errno::EMFILE, Errno::ENFILE => e
          raise "Too many open files when opening RESULT_FIFO: #{e.message}. Check for file descriptor leaks."
        rescue => e
          raise "Failed to open RESULT_FIFO: #{e.class} - #{e.message}"
        end
      end
      payload = "--G_CMD--#{r_cmd.gsub("\n", "\\n")}\n"
      if ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true"
        ts = Time.now.strftime("%H:%M:%S.%L")
        File.open(log_path("galaaz_r_debug.log"), "a") { |f| f.puts "[#{ts}][RUBY_SEND_RESULT_EXACT] #{r_cmd}" }
        File.open(log_path("galaaz_r_debug.log"), "a") { |f| f.puts "[#{ts}][RUBY_SEND_RESULT_PAYLOAD] #{payload.inspect}" }
      end
      File.write(CALLBACK_FIFO, payload)
      debug_r_console("RUBY", "callback result: #{r_cmd.strip[0..200]}#{'...' if r_cmd.length > 200}")
      log_hang_point("eval_r_with_result_in_callback: waiting for stdout until --G_CMD_END--")
      while line = read_stdout_line
        if line.start_with?('--G_CALLBACK--')
          process_callback(line)
          next
        end
        if line.start_with?('--G_ERR--')
          err_msg = line.sub('--G_ERR--', '').strip
          trace_line = read_stdout_line
          trace_msg = (trace_line && trace_line.start_with?('--G_TRACE--')) ? trace_line.sub('--G_TRACE--', '').strip.gsub("\\n", "\n") : nil
          while (drain = read_stdout_line)
            break if drain.include?('--G_CMD_END--') || drain.include?('--G_END--')
          end
          full = "R Error (nested): #{err_msg}"
          full += "\n--- R traceback ---\n#{trace_msg}" if trace_msg && !trace_msg.empty?
          raise full
        end
        break if line.include?('--G_CMD_END--')
      end
      log_hang_point("eval_r_with_result_in_callback: waiting for RESULT_FIFO envelope")
      if tmp_fifo
        begin
          read_result_envelope_from_io(tmp_fifo)
        ensure
          tmp_fifo.close
        end
      else
        read_result_envelope_from_io(fifo_io)
      end
    end

    # Simple callback: three round-trips only (no one-shot) so rspec does not hang.
    def eval_r_with_result_in_callback_simple(r_cmd)
      assignment = r_cmd.gsub(/;.*$/, '')
      var_name = assignment.match(/\.GlobalEnv\$(\w+) <- /)&.[](1) || assignment.match(/\A(\w+) <- /)&.[](1)
      return nil unless var_name
      assignment_one_line = assignment.gsub(/\n+/, "; ")

      eval_r_in_callback(assignment_one_line)
      type_len = eval_r_in_callback("paste(typeof(#{var_name}), length(#{var_name}))")
      return { type: :handle, handle: var_name, r_class: "unknown" } unless type_len && !type_len.strip.empty?
      m = type_len.match(/(integer|double|numeric|logical|character)\s+(\d+)/)
      return { type: :handle, handle: var_name, r_class: "unknown" } unless m
      r_type = m[1]
      len = m[2].to_i
      return { type: :handle, handle: var_name, r_class: r_type } unless len == 1
      printed = eval_r_in_callback(var_name.to_s)
      envelope = parse_callback_scalar_from_print(r_type, printed)
      envelope || { type: :handle, handle: var_name, r_class: r_type }
    end

    # Parse R's printed scalar (e.g. "[1] 200", "[1] 3.14", "[1] TRUE", "[1] \"x\"") into envelope hash.
    def parse_callback_scalar_from_print(r_type, printed)
      return nil unless printed && !printed.strip.empty?
      line = printed.lines.find { |l| l =~ /\[\s*1\s*\]/ }
      return nil unless line
      value_part = line.sub(/\A.*\[\s*1\s*\]\s*/, '').strip
      case r_type
      when "integer"
        { type: :scalar_integer, value: value_part.to_i }
      when "double", "numeric"
        { type: :scalar_double, value: value_part.to_f }
      when "logical"
        v = value_part.match(/\ATRUE\z/i) ? true : (value_part.match(/\AFALSE\z/i) ? false : nil)
        return nil unless v
        { type: :scalar_logical, value: v }
      when "character"
        m = value_part.match(/\A"(.*)"\z/m)
        return nil unless m
        { type: :scalar_character, value: m[1].gsub(/\\\\/, "\\").gsub(/\\n/, "\n").gsub(/\\t/, "\t").gsub(/\\"/, '"') }
      else
        nil
      end
    end

    # Top-level: open RESULT_FIFO on first use, write tryCatch script, source it, read stdout until --G_END--, read one envelope.
    def eval_r_with_result_top_level(r_cmd)
      @eval_r_with_result_depth += 1
      if @eval_r_with_result_depth == 1
        @result_fifo_io = File.open(RESULT_FIFO, File::RDONLY | Fcntl::O_NONBLOCK)
        @result_fifo_io.fcntl(Fcntl::F_SETFL, @result_fifo_io.fcntl(Fcntl::F_GETFL) & ~Fcntl::O_NONBLOCK)
      end
      fifo_io = @result_fifo_io
      begin
        write_eval_r_with_result_script(r_cmd)
        raise "R process is dead. Last command (eval_r_with_result): #{@last_sent_code.inspect}" unless @wait_thr.alive?
        @last_sent_code = r_cmd
        trace_log("eval_r_with_result", r_cmd) if ENV["GALAAZ_TRACE"]
        debug_r_console("RUBY", "top-level result: #{r_cmd.lines.first.to_s.strip[0..150]}#{'...' if r_cmd.lines.size > 1}")
        @stdin.puts("source('#{@tmp_r_path}')")
        @stdin.flush
        log_hang_point("eval_r_with_result_top_level: waiting for stdout until --G_END--")
        read_stdout_until_g_end_for_result
        log_hang_point("eval_r_with_result_top_level: waiting for RESULT_FIFO envelope")
        env = read_result_envelope_from_io(fifo_io)
        raise "R process died during command. Last command (eval_r_with_result): #{@last_sent_code.inspect}" unless @wait_thr.alive?
        puts "DEBUG: eval_r_with_result read_result_envelope=#{env.inspect}" if ENV['GALAAZ_DEBUG']
        env
      ensure
        @eval_r_with_result_depth -= 1
        if @eval_r_with_result_depth == 0
          @result_fifo_io&.close
          @result_fifo_io = nil
        end
      end
    end

    # Write the tryCatch script for eval_r_with_result; sets @tmp_r_path for the caller to source.
    def write_eval_r_with_result_script(r_cmd)
      @script_seq += 1
      @tmp_r_path = "#{CMD_SCRIPT_BASE}_#{@script_seq}.R"
      script_content = <<~R
        tryCatch({
          #{r_cmd}
        }, error = function(e) {
          msg <- conditionMessage(e)
          tb <- paste(capture.output(traceback()), collapse = "\\n")
          cat('--G_ERR--', msg, '\\n', sep='')
          if (nchar(tb) > 0) cat('--G_TRACE--', tb, '\\n', sep='')
        }, finally = {
          cat('--G_END--\\n')
        })
      R
      File.write(@tmp_r_path, script_content)
      log_r_script_if_debug("eval_r_with_result", script_content)
    end

    # Read @stdout until --G_END-- for eval_r_with_result (handles CALLBACK and G_ERR; no output collection).
    def read_stdout_until_g_end_for_result
      while line = read_stdout_line
        raise "R process died (stdout EOF). Last command (eval_r_with_result): #{@last_sent_code.inspect}" if line.nil?
        if line.start_with?('--G_CALLBACK--')
          process_callback(line)
          next
        end
        if line.start_with?('--G_ERR--')
          error_msg = line.sub('--G_ERR--', '').strip
          trace_line = read_stdout_line
          trace_msg = (trace_line && trace_line.start_with?('--G_TRACE--')) ? trace_line.sub('--G_TRACE--', '').strip.gsub("\\n", "\n") : nil
          while (drain = read_stdout_line)
            break if drain.strip == '--G_END--'
          end
          code_hint = @last_sent_code ? "\nR code: #{@last_sent_code.strip[0..500]}#{'...' if @last_sent_code.length > 500}" : ""
          full_msg = "R Error: #{error_msg}#{code_hint}"
          full_msg += "\n--- R traceback ---\n#{trace_msg}" if trace_msg && !trace_msg.empty?
          raise full_msg
        end
        break if line.strip == '--G_END--'
      end
    end

    # Parse --G_CALLBACK--id--handle:class|...--, run the Ruby proc, send --G_RET--result to CALLBACK_FIFO.
    def process_callback(line)
      match = line.match(/--G_CALLBACK--(\d+)--(.*)--/)
      callback_id = match[1].to_i
      handle_pairs = match[2].empty? ? [] : match[2].split('|')

      debug_r_console("CALLBACK_ENTER", "id=#{callback_id} handles=#{handle_pairs.size}") if ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true"

      # Wrap handles in R::Object using pre-parsed classes
      args = handle_pairs.map do |pair|
        handle, r_class = pair.split(':', 2)
        R::Object.build(handle, nil, r_class: r_class)
      end

      # Execute Ruby callback
      proc = R::Support.get_callback(callback_id)
      
      old_in_callback = @in_callback
      @in_callback = true
      begin
        result = proc.call(*args)
      ensure
        @in_callback = old_in_callback
        debug_r_console("CALLBACK_EXIT", "id=#{callback_id}") if ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true"
      end
      
      # Send result back to R via FIFO (--G_RET-- so R returns from the callback)
      File.write(CALLBACK_FIFO, "--G_RET--#{R::Support.parse_arg(result)}\n")
    end

    # Pull an R vector into a Ruby array by type (double, integer, logical, character, symbol); uses DATA_FILE or temp files.
    def pull_vector(var_name)
      type_raw = eval_r("typeof(#{var_name})")
      type = type_raw.match(/\[1\] \"(.*)\"/)[1] rescue "double"
      len_raw = eval_r("length(#{var_name})")
      m = len_raw.match(/\[1\] (.*)/)
      len = m ? m[1].to_i : 0
      return [] if len == 0

      case type
      when "double", "numeric"
        pull_double_vector(var_name, len)
      when "integer"
        pull_integer_vector(var_name, len)
      when "logical"
        # Logicals are 4-byte integers in writeBin: 0=FALSE, 1=TRUE, INT_MIN=NA
        eval_r("writeBin(as.integer(#{var_name}), '#{DATA_FILE}', size=4, endian='little')")
        raf = RandomAccessFile.new(DATA_FILE, "r")
        begin
          buffer = raf.get_channel.map(FileChannel::MapMode::READ_ONLY, 0, len * 4)
          buffer.order(ByteOrder::LITTLE_ENDIAN)
          Array.new(len) do
            val = buffer.get_int
            val == 1 ? true : (val == 0 ? false : R::NA)
          end
        ensure
          raf.close
        end
      when "character"
        tmp_f = "/dev/shm/galaaz_strings.txt"
        eval_r("writeLines(as.character(#{var_name}), '#{tmp_f}')")
        File.readlines(tmp_f).map do |line|
          str = line.chomp
          if str =~ /^rb_obj_(\d+)$/
            R::Support.get_ruby_object(str)
          else
            str
          end
        end
      when "symbol"
        # Extract symbol name and convert to Ruby symbol
        res = eval_r("as.character(#{var_name})")
        # res should be like '[1] "mtcars"'
        if res =~ /^\[1\] \"(.*)\"$/
          $1.gsub("::", "___").gsub(".", "__").to_sym
        else
          res.gsub("::", "___").gsub(".", "__").to_sym
        end
      else
        # Fallback for complex types or unknown
        eval_r(var_name).scan(/\"(.*?)\"/).flatten
      end
    end

    def pull_numeric_vector(var_name, type = 'double')
      pull_vector(var_name)
    end

    # Pull a slice of an integer vector via writeBin to DATA_FILE and memory-mapped read.
    def pull_integer_vector(var_name, total_size, offset = 0, chunk_size = nil)
      chunk_size ||= total_size
      file_size = chunk_size * 4 # integers are 4 bytes

      r_start = offset + 1
      r_end = offset + chunk_size
      eval_r("writeBin(as.integer(#{var_name}[#{r_start}:#{r_end}]), '#{DATA_FILE}', size=4, endian='little')")

      raf = RandomAccessFile.new(DATA_FILE, "rw")
      begin
        buffer = raf.get_channel.map(FileChannel::MapMode::READ_ONLY, 0, file_size)
        buffer.order(ByteOrder::LITTLE_ENDIAN)
        Array.new(chunk_size) { buffer.get_int }
      ensure
        raf.close
      end
    end

    # Pull an R data frame as a Ruby hash of column name => array (numeric columns via pull_numeric_vector).
    def pull_dataframe(var_name)
      feather_file = "/dev/shm/galaaz_df.feather"
      # arrow::write_feather can write to a file
      eval_r("write_feather(#{var_name}, '#{feather_file}')")

      # Now read the feather file using Java Arrow
      # This is complex in pure Java Arrow because Feather is usually IPC
      # Let's see if we can just return the file path for now, 
      # or implement a basic reader.
      # For the sake of Phase 5, let's just return a Ruby Hash of columns.

      # Better: use eval_r to get column names and then pull each column
      col_names_raw = eval_r("names(#{var_name})")
      # Extract names from "[1] \"col1\" \"col2\""
      col_names = col_names_raw.scan(/\"(.*?)\"/).flatten

      df_hash = {}
      col_names.each do |col|
        # Determine column type
        type_raw = eval_r("typeof(#{var_name}$#{col})")
        type = type_raw.match(/\[1\] \"(.*)\"/)[1] rescue "double"
        df_hash[col] = pull_numeric_vector("#{var_name}$#{col}", type)
      end
      df_hash
    end


    # Push a Ruby array of floats to R via DATA_FILE (writeBin); creates or updates var_name.
    def push_double_vector(ruby_array, var_name, offset = nil, total_size = nil)
      size = ruby_array.length
      file_size = size * 8
      
      raf = RandomAccessFile.new(DATA_FILE, "rw")
      begin
        raf.set_length(file_size)
        buffer = raf.get_channel.map(FileChannel::MapMode::READ_WRITE, 0, file_size)
        buffer.order(ByteOrder::LITTLE_ENDIAN)
        
        # Optimized bulk put
        java_array = ruby_array.to_java(:double)
        buffer.as_double_buffer.put(java_array)
        
        if offset && total_size
          # Writing to a slice of an existing vector
          r_start = offset + 1
          r_end = offset + size
          eval_r("#{var_name}[#{r_start}:#{r_end}] <- readBin('#{DATA_FILE}', double(), n=#{size}, size=8, endian='little')")
        else
          # Creating a new vector
          eval_r("#{var_name} <- readBin('#{DATA_FILE}', double(), n=#{size}, size=8, endian='little')")
        end
      ensure
        raf.close
      end
    end

    # Pull a slice of a double vector from R via writeBin to DATA_FILE and memory-mapped read.
    def pull_double_vector(var_name, total_size, offset = 0, chunk_size = nil)
      chunk_size ||= total_size
      file_size = chunk_size * 8
      
      # We tell R to write only the requested slice
      # R indices start at 1
      r_start = offset + 1
      r_end = offset + chunk_size
      eval_r("writeBin(as.double(#{var_name}[#{r_start}:#{r_end}]), '#{DATA_FILE}', size=8, endian='little')")
      
      raf = RandomAccessFile.new(DATA_FILE, "rw")
      begin
        buffer = raf.get_channel.map(FileChannel::MapMode::READ_ONLY, 0, file_size)
        buffer.order(ByteOrder::LITTLE_ENDIAN)
        
        # Bulk read into Java array
        java_array = Java::double[chunk_size].new
        buffer.as_double_buffer.get(java_array)
        java_array.to_a
      ensure
        raf.close
      end
    end

    # Unbox a single R value (scalar or length-1) to Ruby: number, true/false, symbol, string, or rb_obj_* -> Ruby object.
    def pull_value(var_name)
      type_raw = eval_r("typeof(#{var_name})")
      type = type_raw.match(/\[1\] \"(.*)\"/)[1] rescue "double"
      if type == "symbol" || type == "name"
        res = eval_r("as.character(#{var_name})")
        # Extract name from "[1] \"my.name\""
        if res =~ /^\[\d+\]\s+\"(.*)\"$/
          return $1.gsub("::", "___").gsub(".", "__").to_sym
        else
          return res.gsub("::", "___").gsub(".", "__").to_sym
        end
      end

      # If it's a bare handle, we evaluate it to get its printed representation for unboxing
      # unless we specifically wanted to keep it as a handle (but pull_value is for unboxing).
      res = eval_r(var_name)
      # res is like '[1] 42' or '[1] TRUE' or '[1] "hello"'
      if res =~ /^\[\d+\]\s+(.*)$/m
        val = $1.strip
        case val
        when /^"(rb_obj_\d+)"$/
          R::Support.get_ruby_object($1)
        when /^"(.*)"$/
          $1
        when "TRUE"
          true
        when "FALSE"
          false
        when "NA"
          R::NA
        when /^-?\d+\.\d+$/
          val.to_f
        when /^-?\d+$/
          val.to_i
        else
          val
        end
      else
        res
      end
    end

    # Return the printed representation of an R object (as a string), using R's capture2.
    def print_r(var_name)
      res = eval_r("paste(capture2(#{var_name}), collapse='\\n')")
      if res =~ /^\[1\] "(.*)"$/m
        $1.gsub('\\n', "\n")
      else
        res
      end
    end

    # Quit the R process and remove FIFOs and temp files.
    def close
      begin
        @stdin.puts("q(save='no')")
        @wait_thr.join
      rescue
        # Process might already be dead
      ensure
        File.delete(DATA_FILE) if File.exist?(DATA_FILE)
        File.delete(SYNC_FILE) if File.exist?(SYNC_FILE)
        File.delete(CALLBACK_FIFO) if File.exist?(CALLBACK_FIFO)
      end
    end
  end
end
