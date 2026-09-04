# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'securerandom'
require 'time'

module R
  # Background R work in a **child Rscript process** (not the NewBridge gatekeeper).
  #
  # Layer B — installs:
  #   job = R::Job.install('caret')
  #   job.raise_if_failed!
  #
  # Layer C — long arbitrary R (bridge stays free). Default +wait: true+ awaits
  # before returning; with a block, await, yield the job, return the block value:
  #
  #   coef = R::Job.eval(<<~R) { |job| job.load_rds }
  #     fit <- lm(mpg ~ wt, data = mtcars)
  #     saveRDS(coef(fit), result_path)
  #   R
  #
  #   job = R::Job.script('train.R', 'arg1')           # awaits, returns Job
  #   job = R::Job.eval(code, wait: false)             # start only
  #
  class Job
    class Error < StandardError; end
    class Failed < Error; end
    class Timeout < Error; end

    DEFAULT_REPOS = 'https://cloud.r-project.org'
    DEFAULT_LIB = File.expand_path('~/R/x86_64-pc-linux-gnu-library/galaaz')
    JOBS_ROOT = File.expand_path('~/.local/share/galaaz/jobs')
    DEFAULT_RESULT_NAME = 'result.rds'

    attr_reader :id, :kind, :dir, :log_path, :meta_path, :pid, :packages, :lib_dir,
                :script_path, :script_args

    def self.jobs_root
      ENV['GALAAZ_JOBS_DIR'] && !ENV['GALAAZ_JOBS_DIR'].empty? ? File.expand_path(ENV['GALAAZ_JOBS_DIR']) : JOBS_ROOT
    end

    def self.default_lib_dir
      DEFAULT_LIB
    end

    # Install one or more CRAN packages in a child Rscript, then optionally await.
    #
    # With a block: always await, +raise_if_failed!+, yield the job, return the
    # block's value (File.open-style). Without a block: return the +Job+ (awaits
    # when +wait:+ is true, the default).
    #
    # @param packages [String, Array<String>]
    # @param lib_dir [String] install library (added to .libPaths in the child)
    # @param repos [String] CRAN mirror
    # @param wait [Boolean] if true (default), block until the job finishes
    # @param timeout [nil, Numeric] await wall-clock seconds; nil = wait forever
    # @return [R::Job, Object] Job, or the block's return value
    def self.install(*packages, lib_dir: default_lib_dir, repos: DEFAULT_REPOS, wait: true, timeout: nil, &block)
      pkgs = packages.flatten.map(&:to_s).reject(&:empty?)
      raise ArgumentError, 'R::Job.install requires at least one package name' if pkgs.empty?

      FileUtils.mkdir_p(lib_dir)
      FileUtils.mkdir_p(jobs_root)

      with_install_lock do
        job = new(kind: 'install', packages: pkgs, lib_dir: lib_dir)
        job.send(:spawn_install!, repos: repos)
        finish_job(job, wait: wait, timeout: timeout, &block)
      end
    end

    # Run arbitrary R code in a child Rscript (Layer C).
    #
    # The child starts with +lib_dir+ on +.libPaths+, +setwd(job.dir)+, and:
    #   GALAAZ_JOB_DIR  — job directory
    #   result_path     — default +file.path(GALAAZ_JOB_DIR, "result.rds")+
    # Persist outputs with +saveRDS(..., result_path)+ (or any path under +job.dir+),
    # then load on the bridge with +job.load_rds+.
    #
    # With a block: await, raise on failure, yield job, return block value.
    #
    # @param code [String] R source
    # @param lib_dir [String]
    # @param wait [Boolean]
    # @param timeout [nil, Numeric]
    # @return [R::Job, Object]
    def self.eval(code, lib_dir: default_lib_dir, wait: true, timeout: nil, &block)
      raise ArgumentError, 'R::Job.eval requires code' if code.nil? || code.to_s.strip.empty?

      FileUtils.mkdir_p(lib_dir)
      FileUtils.mkdir_p(jobs_root)

      job = new(kind: 'eval', packages: [], lib_dir: lib_dir)
      job.send(:spawn_eval!, code)
      finish_job(job, wait: wait, timeout: timeout, &block)
    end

    # Run an R script file in a child Rscript (Layer C).
    #
    # With a block: await, raise on failure, yield job, return block value.
    #
    # @param path [String] path to +.R+ file
    # @param args [Array<String>] trailing args (+commandArgs(trailingOnly=TRUE)+)
    # @param lib_dir [String]
    # @param wait [Boolean]
    # @param timeout [nil, Numeric]
    # @return [R::Job, Object]
    def self.script(path, *args, lib_dir: default_lib_dir, wait: true, timeout: nil, &block)
      script = File.expand_path(path.to_s)
      raise ArgumentError, "R::Job.script: file not found: #{script}" unless File.file?(script)

      FileUtils.mkdir_p(lib_dir)
      FileUtils.mkdir_p(jobs_root)

      job = new(kind: 'script', packages: [], lib_dir: lib_dir, script_path: script, script_args: args.map(&:to_s))
      job.send(:spawn_script!)
      finish_job(job, wait: wait, timeout: timeout, &block)
    end

    # @api private
    def self.finish_job(job, wait:, timeout:, &block)
      job.wait(timeout: timeout) if wait || block
      if block
        job.raise_if_failed!
        return yield(job)
      end
      job
    end
    private_class_method :finish_job

    def initialize(kind:, packages:, lib_dir:, script_path: nil, script_args: [])
      @kind = kind.to_s
      @packages = packages
      @lib_dir = File.expand_path(lib_dir)
      @script_path = script_path
      @script_args = script_args || []
      @id = "#{@kind}-#{Time.now.utc.strftime('%Y%m%dT%H%M%S')}-#{Process.pid}-#{SecureRandom.hex(3)}"
      @dir = File.join(self.class.jobs_root, @id)
      FileUtils.mkdir_p(@dir)
      @log_path = File.join(@dir, 'job.log')
      @meta_path = File.join(@dir, 'meta.json')
      @exit_path = File.join(@dir, 'exit_code')
      @pid = nil
      @exit_status = nil
    end

    def status
      return :ok if finished? && exit_code == 0
      return :failed if finished? && exit_code != 0
      return :running if alive?

      :unknown
    end

    def alive?
      return false unless @pid

      begin
        Process.kill(0, @pid)
        true
      rescue Errno::ESRCH
        false
      rescue Errno::EPERM
        true
      end
    end

    def finished?
      return true unless @exit_status.nil?
      return true if File.file?(@exit_path) && !alive?

      false
    end

    def exit_code
      return @exit_status.exitstatus if @exit_status.respond_to?(:exitstatus)
      return File.read(@exit_path).to_i if File.file?(@exit_path)

      nil
    end

    # Default RDS path written by child when using +result_path+ / +saveRDS(..., result_path)+.
    def result_path(name = DEFAULT_RESULT_NAME)
      File.join(@dir, name.to_s)
    end

    # Await process completion.
    # @param timeout [nil, Numeric] nil = forever
    # @return [Symbol] final status (:ok or :failed)
    def wait(timeout: nil)
      return status if finished?

      if timeout.nil?
        reap!
      else
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + Float(timeout)
        loop do
          reap_nonblock!
          break if finished?
          if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            kill!
            raise Timeout, "R::Job #{@id} still running after #{timeout}s (pid=#{@pid}, log=#{@log_path})"
          end

          sleep 0.2
        end
      end

      write_exit_file!
      status
    end

    def raise_if_failed!
      st = status
      return self if st == :ok

      if st == :running
        raise Error, "R::Job #{@id} is still running (pid=#{@pid}, log=#{@log_path})"
      end

      tail = File.readable?(@log_path) ? File.read(@log_path).lines.last(40).join : ''
      raise Failed, "R::Job #{@id} failed (exit=#{exit_code}, log=#{@log_path})\n--- log tail ---\n#{tail}"
    end

    # Short sync +readRDS+ on the **bridge** after a successful job.
    # Returns a normal Galaaz R object (same as +R.readRDS(...)+).
    # @param name [String] file under +job.dir+ (default +result.rds+)
    def load_rds(name = DEFAULT_RESULT_NAME)
      raise_if_failed!
      path = result_path(name)
      raise Error, "R::Job #{@id}: result not found: #{path}" unless File.file?(path)

      R.readRDS(path)
    end

    def kill!(signal = 'TERM')
      return unless @pid

      # Spawned with pgroup: true — kill the whole process group (Rscript + make/gcc).
      targets = [-@pid, @pid]
      targets.each do |t|
        begin
          Process.kill(signal, t)
        rescue Errno::ESRCH, Errno::EPERM
          nil
        end
      end
      sleep 0.2
      targets.each do |t|
        begin
          Process.kill('KILL', t)
        rescue Errno::ESRCH, Errno::EPERM
          nil
        end
      end
      reap_nonblock!
      write_exit_file!
    end

    def self.with_install_lock
      FileUtils.mkdir_p(jobs_root)
      lock_path = File.join(jobs_root, 'install.lock')
      File.open(lock_path, File::RDWR | File::CREAT, 0o644) do |lf|
        lf.flock(File::LOCK_EX)
        yield
      ensure
        lf.flock(File::LOCK_UN) rescue nil
      end
    end

    private

    def spawn_install!(repos:)
      # Stale 00LOCK-* dirs remain after kill!-on-timeout and block the next install.
      @packages.each do |pkg|
        lock = File.join(@lib_dir, "00LOCK-#{pkg}")
        FileUtils.rm_rf(lock) if File.exist?(lock)
      end

      pkg_list = @packages.map { |p| "'#{p.gsub("'", "\\\\'")}'" }.join(', ')
      lib_esc = @lib_dir.gsub('\\', '\\\\\\\\').gsub("'", "\\\\'")
      repos_esc = repos.gsub("'", "\\\\'")
      r_code = <<~R
        lib <- '#{lib_esc}'
        dir.create(lib, recursive = TRUE, showWarnings = FALSE)
        .libPaths(c(lib, .libPaths()))
        Sys.setenv(MAKEFLAGS = '-j1')
        options(Ncpus = 1L, repos = '#{repos_esc}')
        pkgs <- c(#{pkg_list})
        message('R::Job install starting: ', paste(pkgs, collapse = ', '))
        message('lib = ', lib)
        install.packages(pkgs, lib = lib, dependencies = NA)
        missing <- pkgs[!pkgs %in% rownames(installed.packages(lib.loc = lib))]
        if (length(missing)) {
          message('Still missing after install: ', paste(missing, collapse = ', '))
          quit(status = 1)
        }
        message('R::Job install OK')
        quit(status = 0)
      R
      spawn_rscript!(r_code)
    end

    def spawn_eval!(code)
      preamble = child_preamble_r
      r_code = <<~R
        #{preamble}
        message('R::Job eval starting')
        tryCatch({
        #{indent_r(code, 2)}
        }, error = function(e) {
          message('R::Job eval error: ', conditionMessage(e))
          quit(status = 1)
        })
        message('R::Job eval OK')
        quit(status = 0)
      R
      spawn_rscript!(r_code)
    end

    def spawn_script!
      preamble = child_preamble_r
      script_esc = @script_path.gsub('\\', '\\\\\\\\').gsub("'", "\\\\'")
      # Persist user script path in job dir for forensics; execution uses absolute path.
      FileUtils.cp(@script_path, File.join(@dir, File.basename(@script_path))) rescue nil
      r_code = <<~R
        #{preamble}
        message('R::Job script starting: #{script_esc}')
        tryCatch({
          source('#{script_esc}', local = FALSE)
        }, error = function(e) {
          message('R::Job script error: ', conditionMessage(e))
          quit(status = 1)
        })
        message('R::Job script OK')
        quit(status = 0)
      R
      spawn_rscript!(r_code, extra_args: @script_args)
    end

    def child_preamble_r
      lib_esc = @lib_dir.gsub('\\', '\\\\\\\\').gsub("'", "\\\\'")
      dir_esc = @dir.gsub('\\', '\\\\\\\\').gsub("'", "\\\\'")
      <<~R
        lib <- '#{lib_esc}'
        job_dir <- '#{dir_esc}'
        dir.create(lib, recursive = TRUE, showWarnings = FALSE)
        dir.create(job_dir, recursive = TRUE, showWarnings = FALSE)
        .libPaths(c(lib, .libPaths()))
        setwd(job_dir)
        Sys.setenv(MAKEFLAGS = '-j1', GALAAZ_JOB_DIR = job_dir)
        options(Ncpus = 1L)
        result_path <- file.path(job_dir, '#{DEFAULT_RESULT_NAME}')
      R
    end

    def indent_r(code, spaces)
      pad = ' ' * spaces
      code.to_s.gsub("\r\n", "\n").lines.map { |line| "#{pad}#{line}" }.join
    end

    def spawn_rscript!(r_code, extra_args: [])
      wrapper_path = File.join(@dir, 'job.R')
      File.write(wrapper_path, r_code)
      log_io = File.open(@log_path, File::WRONLY | File::CREAT | File::TRUNC)
      rscript = ENV['GALAAZ_RSCRIPT'] && !ENV['GALAAZ_RSCRIPT'].empty? ? ENV['GALAAZ_RSCRIPT'] : 'Rscript'
      env = {
        'MAKEFLAGS' => '-j1',
        'GALAAZ_JOB_DIR' => @dir,
        'R_LIBS_USER' => @lib_dir
      }
      cmd = [rscript, '--vanilla', wrapper_path, *extra_args.map(&:to_s)]
      @pid = spawn(env, *cmd, out: log_io, err: log_io, pgroup: true, chdir: @dir)
      log_io.close
      write_meta!
      $stderr.puts "[RUBY] R::Job #{@id} started pid=#{@pid} log=#{@log_path}"
    end

    def write_meta!
      File.write(@meta_path, JSON.pretty_generate(
        id: @id,
        kind: @kind,
        packages: @packages,
        lib_dir: @lib_dir,
        dir: @dir,
        script_path: @script_path,
        script_args: @script_args,
        pid: @pid,
        log_path: @log_path,
        result_path: result_path,
        started_at: Time.now.utc.iso8601
      ))
    end

    def write_exit_file!
      code = exit_code
      File.write(@exit_path, code.nil? ? "-1\n" : "#{code}\n") unless code.nil?
    end

    def reap!
      return if @exit_status

      _pid, @exit_status = Process.wait2(@pid)
    rescue Errno::ECHILD
      @exit_status = read_fake_status_from_file
    end

    def reap_nonblock!
      return if @exit_status

      pid, st = Process.wait2(@pid, Process::WNOHANG)
      @exit_status = st if pid
    rescue Errno::ECHILD
      @exit_status = read_fake_status_from_file if File.file?(@exit_path)
    end

    def read_fake_status_from_file
      return nil unless File.file?(@exit_path)

      code = File.read(@exit_path).to_i
      # Minimal stand-in with exitstatus
      Object.new.tap do |o|
        o.define_singleton_method(:exitstatus) { code }
        o.define_singleton_method(:success?) { code.zero? }
      end
    end
  end
end
