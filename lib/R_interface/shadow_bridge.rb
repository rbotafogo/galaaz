# shadow_bridge.rb
require 'open3'
require 'java'
require 'singleton'
require 'fileutils'

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

    DATA_FILE = "/dev/shm/galaaz_data"
    SYNC_FILE = "/dev/shm/galaaz_sync"
    RESULT_BUFFER = "/dev/shm/galaaz_result"

    CALLBACK_FIFO = "/dev/shm/galaaz_callback_fifo"

    def initialize
      puts "DEBUG: Initializing ShadowBridge instance #{self.object_id}"
      @bridge_ready = false
      @in_callback = false
      # ... rest of initialize
      @allocator = RootAllocator.new

      # Setup FIFO for callback responses
      system("mkfifo #{CALLBACK_FIFO}") unless File.exist?(CALLBACK_FIFO)

      # Start R process with a pipe
      @stdin, @stdout, @stderr, @wait_thr = Open3.popen3("R --vanilla --quiet --slave")
      
      # Log stderr in a separate thread
      Thread.new do
        while line = @stderr.gets
          File.open("galaaz_r_stderr.log", "a") { |f| f.puts "[R STDERR] #{line}" }
        end
      end

      # Setup R environment
      eval_r("library(R.utils)")
      eval_r("library(arrow)")
      eval_r("library(rlang)") 

      eval_r("missing_arg <- function() { quote(f(,0))[[2]] }")
      eval_r("capture2 <- function(obj, ...) { tryCatch({ sink(tt <- textConnection('results','w'), split=FALSE, type = c('output', 'message')); print(obj, ...); sink(); results }, finally = { close(tt); }) }")

      # Per-call result protocol: R writes one envelope per result to shared buffer
      eval_r(<<~GALAAZ_RESULT)
        galaaz_result <- function(x, var_name) {
          path <- "#{RESULT_BUFFER}"
          r_type <- typeof(x)
          r_len <- length(x)
          r_class <- paste(class(x), collapse = " ")
          type_code <- 4L
          len <- 0L
          payload <- raw(0)
          if (r_len == 1 && r_type == "double") {
            type_code <- 0L
            len <- 1L
            rc <- rawConnection(raw(0), "wb")
            writeBin(as.double(x), rc, size = 8, endian = "little")
            payload <- rawConnectionValue(rc)
            close(rc)
          } else if (r_len == 1 && r_type == "integer") {
            type_code <- 1L
            len <- 1L
            rc <- rawConnection(raw(0), "wb")
            writeBin(as.integer(x), rc, size = 4, endian = "little")
            payload <- rawConnectionValue(rc)
            close(rc)
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
          } else if (r_type == "symbol" || r_type == "name") {
            type_code <- 5L
            len <- 1L
            s <- enc2utf8(as.character(x))
            rc <- rawConnection(raw(0), "wb")
            writeBin(as.integer(nchar(s, type = "bytes")), rc, size = 4, endian = "little")
            writeBin(charToRaw(s), rc)
            payload <- rawConnectionValue(rc)
            close(rc)
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
          }
          envelope_rc <- rawConnection(raw(0), "wb")
          writeBin(as.raw(type_code), envelope_rc)
          writeBin(as.integer(len), envelope_rc, size = 4, endian = "little")
          writeBin(payload, envelope_rc)
          envelope <- rawConnectionValue(envelope_rc)
          close(envelope_rc)
          total_len <- as.integer(4 + length(envelope))
          out <- file(path, "wb")
          writeBin(total_len, out, size = 4, endian = "little")
          writeBin(envelope, out)
          close(out)
          invisible(NULL)
        }
      GALAAZ_RESULT

      # Define awt as X11 for Galaaz 2.0 (standard R)
      eval_r("awt <- function(...) { X11(...) }")

      # Add local library path to R
      lib_dir = File.expand_path("~/R/x86_64-pc-linux-gnu-library/galaaz")
      FileUtils.mkdir_p(lib_dir) unless Dir.exist?(lib_dir)
      eval_r(".libPaths(c('#{lib_dir}', .libPaths()))")

      File.write(SYNC_FILE, [0].pack("N"))
      @bridge_ready = true
    end

    def ready?
      @bridge_ready
    end

    def eval_r(code)
      puts "DEBUG: R.eval_r(#{code.inspect})" if ENV['GALAAZ_DEBUG']
      # Ensure code is a string
      code = code.to_s
      ts = Time.now.strftime("%H:%M:%S.%L")

      if @in_callback
        # Recursive call during callback. R is waiting on FIFO.
        File.open("galaaz_r_debug.log", "a") { |f| f.puts "[#{ts}][JRuby Nested] #{code}" }
        File.write(CALLBACK_FIFO, "--G_CMD--#{code.gsub("\n", "\\n")}\n")
        
        output = ""
        while line = @stdout.gets
          File.open("galaaz_r_debug.log", "a") { |f| f.puts "[#{ts}][R stdout Nested] #{line}" }
          if line.start_with?('--G_CALLBACK--')
             process_callback(line)
             next
          end
          if line.start_with?('--G_ERR--')
            error_msg = line.sub('--G_ERR--', '').strip
            raise "R Error (Nested): #{error_msg}\nCode: #{code}"
          end
          break if line.include?('--G_CMD_END--')
          output << line unless line.start_with?('--G_')
        end
        return output.strip
      end

      File.open("galaaz_r_debug.log", "a") { |f| f.puts "[#{ts}][JRuby] #{code.lines.first.strip}#{"..." if code.lines.size > 1}" }
      
      # Use a unique marker for each evaluation to ensure synchronization
      # We wrap in tryCatch to catch errors and finally to ensure --G_END-- is sent.
      # If it's not an assignment, we wrap in print() so source() sends it to stdout.
      
      stripped_code = code.strip
      r_cmd = if stripped_code.empty?
                "NULL"
              elsif stripped_code =~ /^(\w+) <- (.*)$/m
                var = $1
                expr = $2
                if var.start_with?("g2_v") && !var.include?("$")
                  ".GlobalEnv$#{var} <- #{expr}"
                else
                  code
                end
              elsif stripped_code.include?("assign(")
                code
              else
                "print({#{code}\n})"
              end

      tmp_r = "/dev/shm/galaaz_cmd.R"
      File.write(tmp_r, <<~R)
        tryCatch({
          #{r_cmd}
        }, error = function(e) { 
          cat('--G_ERR--', e$message, '\\n', sep='') 
        }, finally = {
          cat('--G_END--\\n')
        })
      R
      
      unless @wait_thr.alive?
        raise "R process is dead. Cannot evaluate code."
      end

      @stdin.puts("source('#{tmp_r}')")
      @stdin.flush

      output = ""
      while line = @stdout.gets
        ts_loop = Time.now.strftime("%H:%M:%S.%L")
        File.open("galaaz_r_debug.log", "a") { |f| f.puts "[#{ts_loop}][R stdout] #{line}" }
        
        if line.start_with?('--G_CALLBACK--')
          process_callback(line)
          next
        end
        if line.start_with?('--G_ERR--')
          error_msg = line.sub('--G_ERR--', '').strip
          raise "R Error: #{error_msg}\nCode: #{code}"
        end
        break if line.include?('--G_END--')
        output << line unless line.start_with?('--G_')
      end
      output.strip
    end

    # Phase 3: Read result buffer written by R galaaz_result(). Returns decoded hash or nil.
    def read_result_envelope
      return nil unless File.exist?(RESULT_BUFFER)
      data = File.binread(RESULT_BUFFER)
      return nil if data.nil? || data.bytesize < 5
      total_len = data.unpack1("V")
      return nil if total_len < 5 || total_len > data.bytesize
      envelope = data.byteslice(4, total_len - 4)
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
        { type: :scalar_character, value: str }
      when 4 # handle only
        return nil if payload.bytesize < 8
        handle_len = payload.byteslice(0, 4).unpack1("V")
        return nil if payload.bytesize < 4 + handle_len + 4
        handle = payload.byteslice(4, handle_len).force_encoding("UTF-8")
        class_len = payload.byteslice(4 + handle_len, 4).unpack1("V")
        return nil if payload.bytesize < 4 + handle_len + 4 + class_len
        r_class = payload.byteslice(4 + handle_len + 4, class_len).force_encoding("UTF-8").strip
        puts "DEBUG: read_result_envelope type=handle handle=#{handle.inspect} r_class=#{r_class.inspect}" if ENV['GALAAZ_DEBUG']
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
    rescue => e
      File.open("galaaz_r_debug.log", "a") { |f| f.puts "[read_result_envelope] #{e.message}" }
      nil
    end

    # Phase 3: Send assignment code + galaaz_result, wait for --G_END--, return envelope or nil.
    def eval_r_with_result(assignment_code)
      stripped = assignment_code.strip
      # Only for .GlobalEnv$var <- expr or var <- expr with var = g2_v*
      m = stripped.match(/\A\.GlobalEnv\$(\w+) <- (.+)\z/m) || stripped.match(/\A(\w+) <- (.+)\z/m)
      unless m && m[1].start_with?("g2_v")
        puts "DEBUG: eval_r_with_result no match for assignment_code=#{assignment_code.inspect}" if ENV['GALAAZ_DEBUG']
        return nil
      end
      var = m[1]
      expr = m[2]
      r_cmd = ".GlobalEnv$#{var} <- #{expr}; galaaz_result(.GlobalEnv$#{var}, '#{var}')"
      tmp_r = "/dev/shm/galaaz_cmd.R"
      File.write(tmp_r, <<~R)
        tryCatch({
          #{r_cmd}
        }, error = function(e) {
          cat('--G_ERR--', e$message, '\\n', sep='')
        }, finally = {
          cat('--G_END--\\n')
        })
      R
      unless @wait_thr.alive?
        raise "R process is dead. Cannot evaluate code."
      end
      @stdin.puts("source('#{tmp_r}')")
      @stdin.flush
      while line = @stdout.gets
        if line.start_with?('--G_CALLBACK--')
          process_callback(line)
          next
        end
        raise "R Error: #{line.sub('--G_ERR--', '').strip}" if line.start_with?('--G_ERR--')
        break if line.include?('--G_END--')
      end
      env = read_result_envelope
      puts "DEBUG: eval_r_with_result read_result_envelope=#{env.inspect}" if ENV['GALAAZ_DEBUG']
      env
    end

    def process_callback(line)
      match = line.match(/--G_CALLBACK--(\d+)--(.*)--/)
      callback_id = match[1].to_i
      handle_pairs = match[2].empty? ? [] : match[2].split('|')

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
      end
      
      # Send result back to R via FIFO
      # Ensure result is converted to an R string
      File.write(CALLBACK_FIFO, R::Support.parse_arg(result) + "\n")
    end

    def pull_vector(var_name)
      type_raw = eval_r("typeof(#{var_name})")
      type = type_raw.match(/\[1\] \"(.*)\"/)[1] rescue "double"
      len_raw = eval_r("length(#{var_name})")
      len = len_raw.match(/\[1\] (.*)/)[1].to_i
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

    def pull_dataframe(var_name)
      # We use Feather (via arrow package) for multi-column transport
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

    def print_r(var_name)
      # Uses capture2 to get the printed representation
      res = eval_r("paste(capture2(#{var_name}), collapse='\\n')")
      # eval_r returns the stripped output, which for the above is [1] "result..."
      # We want to unquote it if it's a single string.
      if res =~ /^\[1\] "(.*)"$/m
        $1.gsub('\\n', "\n")
      else
        res
      end
    end

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
