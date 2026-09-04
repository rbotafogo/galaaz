# frozen_string_literal: true

require 'fileutils'
require 'rbconfig'
require 'open3'
require 'time'

module Galaaz
  module CLI
    BLOG_NAMES = %w[oh_my gknit galaaz_ggplot manual nse_dplyr ruby_plot].freeze
    PROFILES = %w[knit arrow tex bio examples ledger demo].freeze
    CONFIG_DIR = File.join(Dir.home, '.config', 'galaaz')
    PROFILES_DIR = File.join(CONFIG_DIR, 'profiles')
    DEFAULT_BLOGS_DIR = File.join(Dir.home, 'galaaz-blogs')
    DEFAULT_EXAMPLES_DIR = File.join(Dir.home, 'galaaz-examples')
    DEFAULT_LEDGER_DIR = File.join(Dir.home, 'r_on_rails_ledger')
    LEDGER_REPO = 'https://github.com/rbotafogo/r_on_rails_ledger.git'
    BLOGS_MARKER = '.galaaz-blogs'
    EXAMPLES_MARKER = '.galaaz-examples'
    CRAN = 'https://cloud.r-project.org'

    module_function

    def root
      return ENV['GALAAZ_ROOT'] if ENV['GALAAZ_ROOT'] && !ENV['GALAAZ_ROOT'].empty?

      File.expand_path('../..', __dir__)
    end

    def run(argv)
      cmd = argv[0]
      case cmd
      when nil, '-h', '--help', 'help'
        print_help
        0
      when 'setup'
        cmd_setup
      when 'blogs'
        cmd_blogs(argv[1..])
      when 'doctor'
        cmd_doctor
      when 'add'
        cmd_add(argv[1..])
      else
        # Legacy: `galaaz some:rake_task` forwarded to rake (see README / blogs).
        Dir.chdir(root) do
          ok = system('rake', *argv)
          ok ? 0 : 1
        end
      end
    rescue CliError => e
      warn "galaaz: #{e.message}"
      1
    rescue SystemCallError => e
      warn "galaaz: #{e.class}: #{e.message}"
      1
    end

    def print_help
      puts <<~HELP
        Usage: galaaz <command> [args]

        Commands:
          setup                 Build the NewBridge gatekeeper; ensure Rcpp
          blogs init [DIR]      Copy blog sources (default: ~/galaaz-blogs)
                                Options: --force
          doctor                Report Ruby, R, gatekeeper, Rcpp, profiles
          add PROFILE           Install an add-on (idempotent)
                                Profiles: #{PROFILES.join(', ')}

        Legacy: any other argument is passed to rake in the Galaaz root
        (e.g. galaaz master_list:scatter_plot).
      HELP
    end

    # ---- setup ----

    def cmd_setup
      need_cmd!('R')
      need_cmd!('Rscript')
      need_cmd!('make')
      ensure_rcpp!
      bridge = File.join(root, 'ext', 'new_bridge')
      abort_unless(File.directory?(bridge), "missing #{bridge}")
      puts "galaaz setup: make -C #{bridge} all"
      ok = system('make', '-C', bridge, 'all')
      abort_unless(ok, 'make failed building ext/new_bridge')
      so = File.join(bridge, 'galaaz_gatekeeper.so')
      abort_unless(File.file?(so), "gatekeeper missing after build: #{so}")
      mark_profile!('core')
      puts 'galaaz setup: OK'
      puts "You can now run: galaaz doctor"
      puts 'Omarchy menu: Install → Development → Galaaz (add-ons appear after core)'
      0
    end

    # ---- blogs ----

    def cmd_blogs(argv)
      sub = argv[0]
      case sub
      when 'init'
        blogs_init(argv[1..])
      when nil, '-h', '--help'
        puts 'Usage: galaaz blogs init [DIR] [--force]'
        0
      else
        raise CliError, "unknown blogs subcommand: #{sub.inspect} (try: init)"
      end
    end

    def blogs_init(argv)
      force = argv.delete('--force')
      dest = File.expand_path(argv[0] || DEFAULT_BLOGS_DIR)
      src_root = File.join(root, 'blogs')
      abort_unless(File.directory?(src_root), "blogs not found in #{root}")

      if File.exist?(dest)
        entries = Dir.children(dest).reject { |n| n.start_with?('.') }
        if !entries.empty? && !force
          raise CliError, "#{dest} exists and is not empty (use --force to replace)"
        end
        FileUtils.rm_rf(dest) if force
      end
      FileUtils.mkdir_p(dest)

      BLOG_NAMES.each do |name|
        src = File.join(src_root, name)
        abort_unless(File.directory?(src), "missing blog source: #{src}")
        FileUtils.cp_r(src, File.join(dest, name))
        rmd = File.join(dest, name, "#{name}.Rmd")
        abort_unless(File.file?(rmd), "expected #{rmd}")
      end

      File.write(File.join(dest, BLOGS_MARKER), "galaaz blogs init\n")
      puts "galaaz blogs init: #{dest}"
      puts "You can now knit with gknit (after: galaaz add knit)"
      0
    end

    # ---- doctor ----

    def cmd_doctor
      puts "galaaz doctor"
      puts "  root:     #{root}"
      print_ruby_engines

      r_ok = command_present?('R')
      rs_ok = command_present?('Rscript')
      puts "  R:        #{r_ok ? `R --version 2>/dev/null`.lines.first.to_s.strip : 'MISSING'}"
      puts "  Rscript:  #{rs_ok ? 'OK' : 'MISSING'}"

      so = File.join(root, 'ext', 'new_bridge', 'galaaz_gatekeeper.so')
      puts "  gatekeeper: #{File.file?(so) ? so : 'MISSING (run: galaaz setup)'}"

      rcpp = rs_ok && r_namespace?('Rcpp')
      puts "  Rcpp:     #{rcpp ? 'OK' : 'MISSING'}"

      blogs = detect_blogs_dir
      puts "  blogs:    #{blogs || '(not initialized)'}"

      profiles = listed_profiles
      puts "  profiles: #{profiles.empty? ? '(none)' : profiles.join(', ')}"

      setup_ok = r_ok && rs_ok && File.file?(so) && rcpp
      puts setup_ok ? 'galaaz doctor: setup OK' : 'galaaz doctor: setup INCOMPLETE'
      setup_ok ? 0 : 1
    end

    def print_ruby_engines
      puts "  this:     #{RUBY_DESCRIPTION}"
      puts "  engine:   #{RUBY_ENGINE}  (interpreter running doctor)"

      cruby = probe_cruby
      jruby = probe_jruby
      puts "  cruby:    #{cruby || 'MISSING (Omarchy / mise: ruby@3.3+)'}"
      puts "  jruby:    #{jruby || 'MISSING'}"
      if RUBY_ENGINE != 'ruby' && cruby
        puts "  tip:      run under CRuby with: GALAAZ_RUBY=ruby bin/galaaz-ruby …"
      elsif RUBY_ENGINE == 'ruby' && jruby
        puts "  tip:      run under JRuby with: GALAAZ_RUBY=jruby bin/galaaz-ruby …"
      end
    end

    # MRI description if available (PATH ruby may be JRuby via mise).
    def probe_cruby
      return RUBY_DESCRIPTION if RUBY_ENGINE == 'ruby'

      if ENV['GALAAZ_RUBY'] && !ENV['GALAAZ_RUBY'].empty?
        desc = ruby_description_for(ENV['GALAAZ_RUBY'])
        return desc if desc && desc_engine(desc) == 'ruby'
      end

      if command_present?('mise')
        mise_ruby_versions.each do |ver|
          next if ver.include?('jruby')
          desc = ruby_description_for('mise', 'exec', "ruby@#{ver}", '--', 'ruby')
          return desc if desc
        end
      end

      # Last resort: a binary named something other than the jruby-backed `ruby` shim.
      %w[ruby3.3 ruby3.2 ruby3.4].each do |bin|
        desc = ruby_description_for(bin)
        return desc if desc && desc_engine(desc) == 'ruby'
      end
      nil
    end

    def probe_jruby
      return RUBY_DESCRIPTION if RUBY_ENGINE == 'jruby'

      desc = ruby_description_for('jruby')
      return desc if desc

      if command_present?('mise')
        mise_ruby_versions.each do |ver|
          next unless ver.include?('jruby')
          desc = ruby_description_for('mise', 'exec', "ruby@#{ver}", '--', 'ruby')
          return desc if desc
        end
      end
      nil
    end

    def mise_ruby_versions
      out, status = Open3.capture2e('mise', 'ls', 'ruby')
      return [] unless status.success?

      out.lines.filter_map do |line|
        # e.g. "ruby  3.3.12" or "ruby  jruby-10.1.1.0  …"
        m = line.strip.match(/\Aruby\s+(\S+)/)
        m && m[1]
      end.uniq
    end

    def ruby_description_for(*cmd)
      out, status = Open3.capture2e(*cmd, '-e', 'print RUBY_DESCRIPTION')
      return nil unless status.success?
      s = out.to_s.strip
      s.empty? ? nil : s
    rescue Errno::ENOENT
      nil
    end

    def desc_engine(description)
      return 'jruby' if description.downcase.start_with?('jruby')
      return 'truffleruby' if description.downcase.start_with?('truffleruby')
      'ruby'
    end

    # ---- add ----

    def cmd_add(argv)
      profile = argv[0]
      raise CliError, "usage: galaaz add <#{PROFILES.join('|')}>" if profile.nil? || profile.empty?
      raise CliError, "unknown profile: #{profile.inspect}" unless PROFILES.include?(profile)

      require_core_for_add! unless profile == 'demo'
      return add_demo if profile == 'demo'

      if profile_marked?(profile) && profile != 'demo'
        puts "galaaz add #{profile}: already installed (marker present)"
        return 0
      end

      case profile
      when 'knit' then add_knit
      when 'arrow' then add_arrow
      when 'tex' then add_tex
      when 'bio' then add_bio
      when 'examples' then add_examples
      when 'ledger' then add_ledger
      end
    end

    def add_demo
      %w[knit arrow ledger].each do |p|
        code = cmd_add([p])
        return code unless code.zero?
      end
      mark_profile!('demo')
      puts 'galaaz add demo: OK'
      0
    end

    def add_knit
      unless command_present?('pandoc')
        raise CliError,
              'pandoc not on PATH (rmarkdown/gknit need pandoc >= 2.8). ' \
              'Omarchy: omarchy-pkg-add pandoc   Arch: pacman -S pandoc   Debian: apt install pandoc'
      end
      ver = `pandoc --version 2>/dev/null`.lines.first.to_s.strip
      puts "galaaz add knit: #{ver.empty? ? 'pandoc OK' : ver}"

      pkgs = read_pkg_list('knit.txt')
      install_cran!(pkgs)
      extras_path = File.join(root, 'r_requires', 'knit-extras.txt')
      if File.file?(extras_path)
        extras = read_pkg_list('knit-extras.txt')
        unless install_cran_soft!(extras)
          warn 'galaaz add knit: some optional packages are missing (see R messages above)'
        end
      end
      mark_profile!('knit')
      puts 'galaaz add knit: OK'
      puts 'Example knits (after blogs init → ~/galaaz-blogs):'
      puts '  gknit ~/galaaz-blogs/oh_my/oh_my.Rmd'
      puts '  gknit ~/galaaz-blogs/galaaz_ggplot/galaaz_ggplot.Rmd'
      puts '  gknit ~/galaaz-blogs/gknit/gknit.Rmd'
      puts 'Docs: https://rbotafogo.github.io/galaaz/'
      puts '      https://github.com/rbotafogo/galaaz'
      puts 'Omarchy menu: Guide (what\'s next) · Knit demo (oh_my)'
      0
    end

    def add_arrow
      pkgs = read_pkg_list('arrow.txt')
      install_cran!(pkgs)
      if RUBY_ENGINE == 'ruby'
        puts 'galaaz add arrow: gem install red-arrow (CRuby Stage B writer)'
        unless system('gem', 'install', 'red-arrow', '--no-document')
          warn 'galaaz add arrow: red-arrow gem install failed (need Apache Arrow GLib / libarrow-glib). R arrow is installed; Ruby IPC writer may be unavailable.'
        end
      else
        warn 'galaaz add arrow: on JRuby, set GALAAZ_ARROW_JARS (or ~/arrow_jars) and JAVA_OPTS nio opens for Arrow Java'
      end
      mark_profile!('arrow')
      puts 'galaaz add arrow: OK'
      0
    end

    def add_tex
      unless command_present?('pandoc')
        warn 'galaaz add tex: pandoc not on PATH — install via your package manager (e.g. pacman -S pandoc)'
      end
      script = File.join(root, 'bin', 'install-tinytex')
      abort_unless(File.file?(script), "missing #{script}")
      puts 'galaaz add tex: running bin/install-tinytex'
      ok = system(script)
      abort_unless(ok, 'TinyTeX install failed')
      mark_profile!('tex')
      puts 'galaaz add tex: OK'
      0
    end

    def add_bio
      warn 'galaaz add bio: Bioconductor DESeq2 + airway — this can take a long time'
      script = <<~R
        repos <- '#{CRAN}'
        if (!requireNamespace('BiocManager', quietly = TRUE))
          install.packages('BiocManager', repos = repos)
        BiocManager::install(c('DESeq2', 'airway'), update = FALSE, ask = FALSE)
        stopifnot(requireNamespace('DESeq2', quietly = TRUE))
        stopifnot(requireNamespace('airway', quietly = TRUE))
      R
      ok = system('Rscript', '-e', script)
      abort_unless(ok, 'Bioconductor install failed')
      mark_profile!('bio')
      puts 'galaaz add bio: OK'
      0
    end

    def add_examples
      dest = DEFAULT_EXAMPLES_DIR
      src = File.join(root, 'examples')
      abort_unless(File.directory?(src), "examples not found in #{root}")
      if File.exist?(dest) && !Dir.children(dest).reject { |n| n.start_with?('.') }.empty?
        if profile_marked?('examples')
          puts "galaaz add examples: already at #{dest}"
          return 0
        end
        raise CliError, "#{dest} exists and is not empty"
      end
      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.rm_rf(dest) if File.exist?(dest)
      FileUtils.cp_r(src, dest)
      File.write(File.join(dest, EXAMPLES_MARKER), "galaaz add examples\n")
      mark_profile!('examples')
      puts "galaaz add examples: #{dest}"
      0
    end

    def add_ledger
      unless profile_marked?('arrow') || r_namespace?('arrow')
        puts 'galaaz add ledger: installing arrow profile first'
        code = add_arrow
        return code unless code.zero?
      end

      dest = DEFAULT_LEDGER_DIR
      if File.directory?(dest) && File.file?(File.join(dest, 'Gemfile'))
        puts "galaaz add ledger: using existing #{dest}"
      else
        need_cmd!('git')
        abort_unless(!File.exist?(dest) || Dir.empty?(dest), "#{dest} exists but is not an empty/ledger dir")
        FileUtils.rm_rf(dest) if File.exist?(dest)
        puts "galaaz add ledger: git clone #{LEDGER_REPO}"
        ok = system('git', 'clone', '--depth', '1', LEDGER_REPO, dest)
        abort_unless(ok, 'git clone failed (is the ledger repo public/reachable?)')
      end

      gemfile = File.join(dest, 'Gemfile')
      text = File.read(gemfile)
      rewritten = text.gsub(/gem\s+["']galaaz["']\s*,\s*path:\s*["'][^"']+["']/, 'gem "galaaz"')
      if rewritten != text
        File.write(gemfile, rewritten)
        puts 'galaaz add ledger: Gemfile now uses RubyGems galaaz (no path:)'
      end

      Dir.chdir(dest) do
        need_cmd!('bundle')
        abort_unless(system('bundle', 'install'), 'bundle install failed')
        # Ensure gatekeeper for the bundled/installed gem path when possible.
        system('galaaz', 'setup') || warn('galaaz add ledger: galaaz setup returned non-zero; check gatekeeper')
        abort_unless(system('bin/rails', 'db:prepare'), 'rails db:prepare failed')
        abort_unless(system({ 'SEED_PROFILE' => 'fast' }, 'bin/rails', 'db:seed'), 'rails db:seed failed')
      end

      mark_profile!('ledger')
      puts 'galaaz add ledger: OK'
      puts "You can now run: cd #{dest} && bin/dev"
      puts 'Then open http://localhost:3000 — portfolio → Run stress test'
      0
    end

    # ---- helpers ----

    class CliError < StandardError; end

    def abort_unless(cond, msg)
      raise CliError, msg unless cond
    end

    def need_cmd!(name)
      abort_unless(command_present?(name), "missing command: #{name}")
    end

    def command_present?(name)
      system('bash', '-c', "command -v #{shell_escape(name)} >/dev/null 2>&1")
    end

    def shell_escape(s)
      s.gsub("'", "'\\''")
    end

    def ensure_rcpp!
      return if r_namespace?('Rcpp')

      puts 'galaaz setup: installing Rcpp from CRAN'
      install_cran!(['Rcpp'])
    end

    # Omarchy/Arch: /usr/lib/R/library is not writable for normal users.
    def r_lib_bootstrap
      <<~R
        lib <- Sys.getenv("R_LIBS_USER", unset = "")
        if (!nzchar(lib)) {
          lib <- file.path(Sys.getenv("HOME"), ".local", "lib", "R", "library")
          Sys.setenv(R_LIBS_USER = lib)
        }
        dir.create(lib, recursive = TRUE, showWarnings = FALSE)
        .libPaths(c(lib, .libPaths()))
        renviron <- file.path(Sys.getenv("HOME"), ".Renviron")
        line <- paste0("R_LIBS_USER=", lib)
        if (!file.exists(renviron) || !any(grepl("^R_LIBS_USER=", readLines(renviron, warn = FALSE)))) {
          cat(line, "\\n", file = renviron, append = TRUE)
        }
      R
    end

    def r_namespace?(pkg)
      script = "#{r_lib_bootstrap}\nquit(status=if (requireNamespace('#{pkg}', quietly=TRUE)) 0 else 1)"
      _out, status = Open3.capture2e('Rscript', '-e', script)
      status.success?
    rescue Errno::ENOENT
      false
    end

    def install_cran!(pkgs)
      list = pkgs.map { |p| "'#{p}'" }.join(', ')
      script = <<~R
        #{r_lib_bootstrap}
        repos <- '#{CRAN}'
        pkgs <- c(#{list})
        inst <- rownames(installed.packages())
        need <- pkgs[!pkgs %in% inst]
        if (length(need)) {
          message('Installing into ', lib, ': ', paste(need, collapse=', '))
          install.packages(need, lib = lib, repos = repos)
        }
        missing <- pkgs[!pkgs %in% rownames(installed.packages())]
        if (length(missing)) {
          message('Still missing: ', paste(missing, collapse=', '))
          quit(status = 1)
        }
      R
      ok = system('Rscript', '-e', script)
      abort_unless(ok, "failed to install CRAN packages: #{pkgs.join(', ')}")
    end

    def install_cran_soft!(pkgs)
      return if pkgs.empty?

      list = pkgs.map { |p| "'#{p}'" }.join(', ')
      script = <<~R
        #{r_lib_bootstrap}
        repos <- '#{CRAN}'
        pkgs <- c(#{list})
        inst <- rownames(installed.packages())
        need <- pkgs[!pkgs %in% inst]
        if (length(need)) {
          message('Installing (optional) into ', lib, ': ', paste(need, collapse=', '))
          tryCatch(
            install.packages(need, lib = lib, repos = repos),
            error = function(e) message(e)
          )
        }
        missing <- pkgs[!pkgs %in% rownames(installed.packages())]
        if (length(missing)) {
          message('Optional still missing: ', paste(missing, collapse=', '))
          quit(status = 2)
        }
        quit(status = 0)
      R
      status = system('Rscript', '-e', script)
      status
    end

    def read_pkg_list(name)
      path = File.join(root, 'r_requires', name)
      abort_unless(File.file?(path), "missing #{path}")
      File.readlines(path).map(&:strip).reject { |l| l.empty? || l.start_with?('#') }
    end

    def require_core_for_add!
      so = File.join(root, 'ext', 'new_bridge', 'galaaz_gatekeeper.so')
      unless File.file?(so) && r_namespace?('Rcpp')
        raise CliError, 'core Galaaz incomplete (need gatekeeper + Rcpp). Run: galaaz setup'
      end
    end

    def profile_marked?(name)
      File.file?(File.join(PROFILES_DIR, name))
    end

    def mark_profile!(name)
      FileUtils.mkdir_p(PROFILES_DIR)
      File.write(File.join(PROFILES_DIR, name), "#{Time.now.utc.iso8601}\n")
    end

    def listed_profiles
      return [] unless File.directory?(PROFILES_DIR)

      Dir.children(PROFILES_DIR).sort
    end

    def detect_blogs_dir
      candidates = [DEFAULT_BLOGS_DIR]
      candidates.each do |d|
        return d if File.file?(File.join(d, BLOGS_MARKER))
      end
      nil
    end
  end
end
