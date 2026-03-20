# frozen_string_literal: true

require 'open3'

module NewBridge
  module Bootstrap
    # Windows-first bootstrap executed from WSL.
    # Supports:
    # - --check: diagnostics only
    # - --apply: apply WSL-side fixes when possible
    class WindowsBootstrap
      attr_reader :checks, :actions

      def initialize(out: $stdout, err: $stderr, command_runner: nil, env: ENV, wsl_override: nil)
        @out = out
        @err = err
        @runner = command_runner || method(:default_runner)
        @env = env
        @wsl_override = wsl_override
        @checks = []
        @actions = []
        @selected_runtime_mode = :docker
      end

      def run(mode: :check, runtime_mode: :docker)
        unless %i[check apply].include?(mode)
          raise ArgumentError, "invalid mode=#{mode} (expected :check or :apply)"
        end

        @selected_runtime_mode = resolve_runtime_mode(runtime_mode)
        header(mode)
        evaluate_checks

        if mode == :apply
          apply_fixes_for_selected_runtime
          evaluate_checks(reset: true)
        end

        summary(mode)
      end

      private

      def header(mode)
        @out.puts "Galaaz bootstrap (windows/wsl) - mode=#{mode}, runtime=#{@selected_runtime_mode}"
      end

      def evaluate_checks(reset: false)
        @checks.clear if reset
        add_check('wsl', wsl?, 'WSL2 environment available')
        add_check('docker_cli', command_exists?('docker'), 'docker CLI available in WSL')
        add_check('docker_daemon', docker_daemon_ok?, 'docker daemon reachable from WSL')
        add_check('docker_compose', docker_compose_ok?, 'docker compose plugin available')
        add_check('ruby', command_exists?('ruby'), 'ruby available')
        add_check('r', command_exists?('R'), 'R available')
        add_check('rcpp', rcpp_ok?, 'Rcpp package available')
      end

      def add_check(name, ok, message)
        @checks << { name: name, ok: ok, message: message }
        @out.puts format("%-16s %s - %s", name, ok ? 'PASS' : 'FAIL', message)
      end

      def apply_fixes_for_selected_runtime
        if @selected_runtime_mode == :local
          apply_local_runtime_fixes
        else
          apply_wsl_docker_fixes
        end
      end

      def apply_wsl_docker_fixes
        @out.puts 'Applying WSL-side fixes where possible...'

        unless wsl?
          @actions << 'not_wsl_skip_apply'
          @out.puts 'SKIP: apply mode is intended for WSL environments.'
          return
        end

        unless command_exists?('docker')
          install_docker_in_wsl
        end

        if command_exists?('docker') && !docker_compose_ok?
          install_docker_compose_plugin
        end

        if command_exists?('docker') && !docker_daemon_ok?
          @actions << 'manual_docker_desktop_integration_required'
          @out.puts 'MANUAL: Docker daemon is not reachable. If using Docker Desktop, enable WSL integration for this distro.'
        end
      end

      def apply_local_runtime_fixes
        @out.puts 'Applying local-runtime fixes (R in WSL)...'
        @actions << 'install_local_r_wsl'
        run_ok('sudo apt-get update')
        run_ok('sudo apt-get install -y r-base r-base-dev')
        run_ok(%q{Rscript -e "if(!requireNamespace('Rcpp', quietly=TRUE)) install.packages('Rcpp', repos='https://cloud.r-project.org/')"})
      end

      def install_docker_in_wsl
        @out.puts 'Attempting docker install in WSL (apt)...'
        @actions << 'install_docker_wsl'
        ok = run_ok('sudo apt-get update') &&
             run_ok('sudo apt-get install -y docker.io')
        ok = install_compose_package if ok
        run_ok("sudo usermod -aG docker #{@env['USER']}") if ok && @env['USER']
        run_ok('sudo service docker start || sudo systemctl start docker')
      end

      def install_docker_compose_plugin
        @out.puts 'Attempting docker compose install (apt)...'
        @actions << 'install_docker_compose_plugin'
        run_ok('sudo apt-get update')
        install_compose_package
      end

      # Package naming differs across Ubuntu/Debian variants.
      # Try known options in order.
      def install_compose_package
        run_ok('sudo apt-get install -y docker-compose-plugin') ||
          run_ok('sudo apt-get install -y docker-compose-v2') ||
          run_ok('sudo apt-get install -y docker-compose')
      end

      def summary(mode)
        failed = @checks.reject { |c| c[:ok] }
        required = required_checks(@selected_runtime_mode)
        required_failed = failed.select { |c| required.include?(c[:name]) }
        ready = required_failed.empty?
        exit_code =
          if ready
            0
          elsif mode == :apply && required_failed.any? { |c| c[:name] == 'docker_daemon' }
            2
          else
            1
          end

        @out.puts '-' * 60
        @out.puts "Checks: #{@checks.count { |c| c[:ok] }}/#{@checks.size} passed"
        @out.puts "Actions: #{@actions.join(', ')}" unless @actions.empty?
        local_runtime_hint
        print_remediation(required_failed, mode)
        @out.puts "Ready: #{ready ? 'YES' : 'NO'}"

        {
          mode: mode,
          runtime_mode: @selected_runtime_mode,
          checks: @checks,
          actions: @actions,
          ready: ready,
          exit_code: exit_code
        }
      end

      def print_remediation(failed, mode)
        return if failed.empty?

        failed_names = failed.map { |f| f[:name] }
        @out.puts 'Remediation:'

        if failed_names.include?('docker_cli')
          @out.puts '- Docker CLI missing in WSL.'
          @out.puts '  REQUIRED on Windows: install Docker Desktop and enable WSL integration.'
          @out.puts '  Download: https://www.docker.com/products/docker-desktop/'
          @out.puts '  Run: sudo apt-get update && sudo apt-get install -y docker.io docker-compose-v2 || sudo apt-get install -y docker-compose'
        end

        if failed_names.include?('docker_daemon') && wsl?
          @out.puts '- Docker daemon unreachable from WSL.'
          @out.puts '  Docker Desktop with WSL integration is RECOMMENDED for container/multi-version runtime.'
          @out.puts '  Download: https://www.docker.com/products/docker-desktop/'
          @out.puts '  Then:'
          @out.puts '    1) Open Docker Desktop > Settings > Resources > WSL Integration'
          @out.puts '    2) Enable integration for this distro'
          @out.puts '    3) Apply & Restart Docker Desktop'
          @out.puts '    4) Re-run: docker info'
          @out.puts '  If local R is available, you can run now with local runtime mode:'
          @out.puts '    ruby bin/galaaz-bootstrap --check --runtime local'
          @out.puts '  (Advanced fallback) If you do NOT use Docker Desktop, run a Linux daemon in WSL manually.'
        end

        if failed_names.include?('docker_compose')
          @out.puts '- Docker compose unavailable.'
          @out.puts '  Try: sudo apt-get install -y docker-compose-v2 || sudo apt-get install -y docker-compose'
        end

        if failed_names.include?('rcpp')
          @out.puts "- Rcpp missing."
          @out.puts "  Run: Rscript -e \"install.packages('Rcpp', repos='https://cloud.r-project.org/')\""
        end

        @out.puts "After fixes, run: ruby bin/galaaz-bootstrap --check"
        @out.puts "(mode=#{mode})"
      end

      def local_runtime_hint
        return unless command_exists?('R')

        version = run_capture("R --version | head -n 1")
        @out.puts "Local runtime available: #{version}" unless version.empty?
      end

      def required_checks(runtime_mode)
        case runtime_mode
        when :local
          %w[wsl ruby r rcpp]
        else
          %w[wsl docker_cli docker_daemon docker_compose ruby]
        end
      end

      def resolve_runtime_mode(runtime_mode)
        case runtime_mode
        when :docker, :local
          runtime_mode
        when :auto
          if command_exists?('R') && rcpp_ok?
            @out.puts 'Auto runtime selection: local (R + Rcpp already available).'
            :local
          elsif command_exists?('docker')
            @out.puts 'Auto runtime selection: docker (local R not ready).'
            :docker
          else
            @out.puts 'Auto runtime selection: docker (fallback).'
            :docker
          end
        else
          raise ArgumentError, "invalid runtime_mode=#{runtime_mode} (expected :docker, :local, :auto)"
        end
      end

      def wsl?
        return @wsl_override unless @wsl_override.nil?

        release = run_capture('uname -r')
        release.downcase.include?('microsoft') || File.exist?('/proc/sys/fs/binfmt_misc/WSLInterop')
      end

      def command_exists?(cmd)
        run_ok("command -v #{cmd}")
      end

      def docker_daemon_ok?
        run_ok("docker info --format '{{.ServerVersion}}'")
      end

      def docker_compose_ok?
        run_ok('docker compose version')
      end

      def rcpp_ok?
        run_ok(%q{Rscript -e "quit(status = ifelse(requireNamespace('Rcpp', quietly=TRUE), 0, 1))"})
      end

      def run_ok(cmd)
        ok, out, err, _status = execute(cmd)
        unless ok
          details = [out, err].compact.map(&:strip).reject(&:empty?).join("\n")
          @out.puts("FAILED: #{cmd}")
          @out.puts(details) unless details.empty?
        end
        ok
      end

      def run_capture(cmd)
        _ok, out, _err, _status = execute(cmd)
        out.to_s.strip
      end

      def execute(cmd)
        @runner.call(cmd)
      end

      def default_runner(cmd)
        out, err, st = Open3.capture3('bash', '-lc', cmd)
        [st.success?, out, err, st.exitstatus]
      end
    end
  end
end

