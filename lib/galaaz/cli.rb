# frozen_string_literal: true

require 'fileutils'
require 'rbconfig'
require 'open3'
require 'time'
require 'tmpdir'

module Galaaz
  module CLI
    BLOG_NAMES = %w[
      oh_my gknit galaaz_ggplot galaaz_2_0 r_on_rails_ledger manual nse_dplyr ruby_plot
    ].freeze
    PROFILES = %w[knit arrow tex bio examples ledger demo].freeze
    CONFIG_DIR = File.join(Dir.home, '.config', 'galaaz')
    PROFILES_DIR = File.join(CONFIG_DIR, 'profiles')
    DEFAULT_BLOGS_DIR = File.join(Dir.home, 'galaaz-blogs')
    DEFAULT_EXAMPLES_DIR = File.join(Dir.home, 'galaaz-examples')
    DEFAULT_LEDGER_DIR = File.join(Dir.home, 'r_on_rails_ledger')
    LEDGER_REPO = 'https://github.com/rbotafogo/r_on_rails_ledger.git'
    OMARCHY_GITHUB_REPO = 'rbotafogo/galaaz'
    OMARCHY_DEFAULT_GIT_REF = 'galaaz2_0'
    # [source under script/omarchy/, dest basename under ~/.local/bin, executable?]
    OMARCHY_BIN_FILES = [
      ['install-galaaz.sh', 'omarchy-install-galaaz', true],
      ['remove-galaaz.sh', 'omarchy-remove-galaaz', true],
      ['galaaz-add.sh', 'omarchy-galaaz-add', true],
      ['galaaz-guide.sh', 'omarchy-galaaz-guide', true],
      ['galaaz-gknit.sh', 'omarchy-galaaz-gknit', true],
      ['debug-galaaz.sh', 'omarchy-galaaz-debug', true]
    ].freeze
    OMARCHY_MENU_FILE = 'omarchy-menu.jsonc'
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
      when 'omarchy'
        cmd_omarchy(argv[1..] || [])
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
                                and sty/galaaz.sty for PDF headers
                                Options: --force
          doctor                Report Ruby, R, gatekeeper, Rcpp, sty, profiles
          add PROFILE           Install an add-on (idempotent)
                                Profiles: #{PROFILES.join(', ')}
          omarchy [install]     Install Omarchy menu overlay (bundled in gem)
                                Options: --from-git [--ref REF]
          omarchy status        Show whether overlay helpers are installed

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
      puts 'On Omarchy: galaaz omarchy   # install menu overlay (gem-bundled)'
      0
    end

    # ---- omarchy overlay ----

    def cmd_omarchy(argv)
      argv = argv.dup
      case argv[0]
      when nil, 'install'
        argv.shift if argv[0] == 'install'
        omarchy_install(argv)
      when 'status'
        omarchy_status
      when '-h', '--help', 'help'
        print_omarchy_help
        0
      else
        if argv[0].to_s.start_with?('-')
          omarchy_install(argv)
        else
          raise CliError, "unknown omarchy subcommand: #{argv[0].inspect} (try: install|status)"
        end
      end
    end

    def print_omarchy_help
      puts <<~HELP
        Usage: galaaz omarchy [install|status] [options]

          install           Copy menu helpers from the gem (default)
          install --from-git [--ref REF]
                            Pull script/omarchy from GitHub instead of the gem
                            Default REF: #{OMARCHY_DEFAULT_GIT_REF} (or GALAAZ_OMARCHY_REF)
          status            Show installed overlay paths

        Writes:
          ~/.local/bin/omarchy-install-galaaz (and add/remove/guide/gknit/debug)
          ~/.config/omarchy/extensions/omarchy-menu.jsonc

        Then: Super+Space → Install → Development → Galaaz
      HELP
    end

    def omarchy_install(argv)
      argv = argv.dup
      from_git = argv.delete('--from-git') || argv.delete('--github')
      ref = nil
      if (i = argv.index('--ref'))
        argv.delete_at(i)
        ref = argv.delete_at(i)
        raise CliError, '--ref requires a branch/tag/commit' if ref.nil? || ref.empty?
      end
      raise CliError, "unknown omarchy install args: #{argv.join(' ')}" unless argv.empty?

      src =
        if from_git
          ref = ENV['GALAAZ_OMARCHY_REF'] if ref.nil? || ref.empty?
          ref = OMARCHY_DEFAULT_GIT_REF if ref.nil? || ref.empty?
          fetch_omarchy_overlay_from_git!(ref)
        else
          omarchy_overlay_dir_bundled
        end

      begin
        install_omarchy_overlay_from!(src)
      ensure
        FileUtils.rm_rf(src) if from_git && src && src.start_with?(Dir.tmpdir)
      end
      puts 'galaaz omarchy: OK'
      puts 'Next: Super+Space → Install → Development → Galaaz → Galaaz (core)'
      puts 'Or: omarchy-install-galaaz'
      0
    end

    def omarchy_status
      bin = File.expand_path('~/.local/bin')
      menu = File.expand_path('~/.config/omarchy/extensions/omarchy-menu.jsonc')
      puts 'galaaz omarchy status'
      OMARCHY_BIN_FILES.each do |_src, dest, _exe|
        path = File.join(bin, dest)
        puts "  #{dest}: #{File.file?(path) ? path : 'MISSING'}"
      end
      puts "  menu: #{File.file?(menu) ? menu : 'MISSING'}"
      bundled = File.join(root, 'script', 'omarchy')
      puts "  gem overlay: #{File.directory?(bundled) ? bundled : 'MISSING (reinstall gem)'}"
      0
    end

    def omarchy_overlay_dir_bundled
      d = File.join(root, 'script', 'omarchy')
      abort_unless(File.directory?(d), "Omarchy overlay missing from gem (#{d}). Reinstall galaaz.")
      abort_unless(
        File.file?(File.join(d, 'install-galaaz.sh')) && File.file?(File.join(d, OMARCHY_MENU_FILE)),
        "incomplete Omarchy overlay in gem (#{d})"
      )
      d
    end

    def fetch_omarchy_overlay_from_git!(ref)
      need_cmd!('curl')
      tmp = Dir.mktmpdir('galaaz-omarchy-')
      base = "https://raw.githubusercontent.com/#{OMARCHY_GITHUB_REPO}/#{ref}/script/omarchy"
      puts "galaaz omarchy: fetching #{base}/…"
      names = OMARCHY_BIN_FILES.map(&:first) + [OMARCHY_MENU_FILE]
      names.uniq.each do |name|
        url = "#{base}/#{name}"
        dest = File.join(tmp, name)
        ok = system('curl', '-fsSL', '-o', dest, url)
        unless ok && File.file?(dest) && File.size(dest).positive?
          FileUtils.rm_rf(tmp)
          raise CliError, "failed to download #{url} (check --ref #{ref})"
        end
        puts "  got #{name}"
      end
      tmp
    end

    def install_omarchy_overlay_from!(src_dir)
      bin = File.expand_path('~/.local/bin')
      ext = File.expand_path('~/.config/omarchy/extensions')
      FileUtils.mkdir_p(bin)
      FileUtils.mkdir_p(ext)

      OMARCHY_BIN_FILES.each do |src_name, dest_name, executable|
        src = File.join(src_dir, src_name)
        abort_unless(File.file?(src), "missing #{src}")
        dest = File.join(bin, dest_name)
        FileUtils.cp(src, dest)
        FileUtils.chmod(0o755, dest) if executable
        puts "galaaz omarchy: #{dest}"
      end

      menu_src = File.join(src_dir, OMARCHY_MENU_FILE)
      abort_unless(File.file?(menu_src), "missing #{menu_src}")
      menu_dest = File.join(ext, OMARCHY_MENU_FILE)
      FileUtils.cp(menu_src, menu_dest)
      puts "galaaz omarchy: #{menu_dest}"
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
      install_galaaz_sty_for_blogs!(dest)
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
      if blogs
        sty = File.join(File.dirname(blogs), 'sty', 'galaaz.sty')
        puts "  sty:      #{File.file?(sty) ? sty : "MISSING (expected #{sty} for PDF blogs)"}"
      end

      profiles = listed_profiles
      puts "  profiles: #{profiles.empty? ? '(none)' : profiles.join(', ')}"

      pdf = command_present?('pdflatex')
      puts "  pdflatex: #{pdf ? `pdflatex --version 2>/dev/null`.lines.first.to_s.strip : 'MISSING (galaaz add tex)'}"

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
      # R 'arrow' needs a matching libarrow. Compiling Arrow C++ + Boost from the
      # CRAN source tarball is fragile (especially Arch/Omarchy). Distro libarrow
      # (e.g. Arch extra/arrow) often mismatches the CRAN package major and then
      # pkg-config configure fails. Apache's version-matched prebuilt libarrow is
      # the reliable automated path — HTTPS from Apache, no interactive steps.
      prepare_arrow_cran_env!
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

    # Env for install.packages("arrow") — see https://arrow.apache.org/docs/r/articles/install.html
    def prepare_arrow_cran_env!
      ENV['LIBARROW_BINARY'] = 'true'
      ENV['NOT_CRAN'] = 'true'
      # Do not fall back to the Boost/C++ source build that breaks on Arch.
      ENV['LIBARROW_BUILD'] = 'false'
      # Avoid linking against a mismatched system libarrow (e.g. pacman 24.x vs CRAN 25.x).
      ENV['ARROW_USE_PKG_CONFIG'] = 'false'
      puts 'galaaz add arrow: LIBARROW_BINARY=true (Apache prebuilt libarrow; no source build)'
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
      ensure_pdflatex_on_path!
      # Blog PDFs use in_header: ../../sty/galaaz.sty → sibling of galaaz-blogs.
      install_galaaz_sty_for_blogs!(detect_blogs_dir || DEFAULT_BLOGS_DIR)
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

      ensure_ledger_galaaz_gemfile!(File.join(dest, 'Gemfile'))

      Dir.chdir(dest) do
        need_cmd!('bundle')
        ensure_ledger_bundler!
        # Fresh clone: install the full lockfile under the app's Ruby (mise .ruby-version).
        # Do not run `bundle update` first — that can mix PATH Ruby with app Ruby and skip install.
        puts 'galaaz add ledger: bundle install'
        abort_unless(ledger_bundle('install'), 'bundle install failed')
        puts 'galaaz add ledger: bundle update galaaz'
        ledger_bundle('update', 'galaaz') ||
          warn('galaaz add ledger: bundle update galaaz returned non-zero (continuing with installed galaaz)')
        puts 'galaaz add ledger: bundle exec galaaz setup'
        unless ledger_bundle('exec', 'galaaz', 'setup')
          warn('galaaz add ledger: bundle exec galaaz setup failed; trying PATH galaaz setup')
          system('galaaz', 'setup') ||
            warn('galaaz add ledger: galaaz setup returned non-zero; check gatekeeper')
        end
        abort_unless(ledger_bundle('exec', 'rails', 'db:prepare'), 'rails db:prepare failed')
        abort_unless(ledger_bundle('exec', 'rails', 'db:migrate'), 'rails db:migrate failed')
        abort_unless(
          ledger_bundle_env({ 'SEED_PROFILE' => 'fast' }, 'exec', 'rails', 'db:seed'),
          'rails db:seed failed'
        )
        # builds/tailwind.css is gitignored — Propshaft needs a one-shot build for rails s
        # (bin/dev runs tailwindcss:watch and would also create it).
        puts 'galaaz add ledger: rails tailwindcss:build'
        abort_unless(
          ledger_bundle('exec', 'rails', 'tailwindcss:build'),
          'rails tailwindcss:build failed (tailwind.css missing for Propshaft)'
        )
      end

      mark_profile!('ledger')
      puts 'galaaz add ledger: OK'
      puts "You can now run: cd #{dest} && bin/dev"
      puts 'Then open http://localhost:3000 — portfolio → Run stress test'
      0
    end

    # Run bundle under mise so .ruby-version / .tool-versions match Omarchy PATH ruby.
    def ledger_bundle(*args)
      if command_present?('mise')
        system('mise', 'x', '--', 'bundle', *args)
      else
        system('bundle', *args)
      end
    end

    def ledger_bundle_env(env, *args)
      if command_present?('mise')
        system(env, 'mise', 'x', '--', 'bundle', *args)
      else
        system(env, 'bundle', *args)
      end
    end

    def ensure_ledger_bundler!
      locked = nil
      if File.file?('Gemfile.lock')
        locked = File.read('Gemfile.lock')[/BUNDLED WITH\s+(\d+\.\d+(?:\.\d+)?)/, 1]
      end
      puts "galaaz add ledger: ensure bundler#{locked ? " #{locked}" : ''}"
      if command_present?('mise')
        cmd = ['mise', 'x', '--', 'gem', 'install', 'bundler', '--no-document']
        cmd.insert(-2, '-v', locked) if locked
        system(*cmd) || warn('galaaz add ledger: gem install bundler returned non-zero')
      elsif locked
        system('gem', 'install', 'bundler', '-v', locked, '--no-document') ||
          warn('galaaz add ledger: gem install bundler returned non-zero')
      end
    end

    # Ledger repo may ship `gem "galaaz", path: "..."`. Standalone installs use RubyGems
    # (CRuby or JRuby), unpinned, so `bundle update galaaz` takes the newest published gem.
    def ensure_ledger_galaaz_gemfile!(gemfile)
      text = File.read(gemfile)
      line = 'gem "galaaz"'
      rewritten = text.gsub(/^\s*gem\s+["']galaaz["'].*$/, line)
      if rewritten == text && text !~ /^\s*gem\s+["']galaaz["']/
        rewritten = text + "\n#{line}\n"
      end
      if rewritten != text
        File.write(gemfile, rewritten)
        puts 'galaaz add ledger: Gemfile → gem "galaaz" (RubyGems latest; not path:)'
      end
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

    # PDF YAML uses in_header: "../../sty/galaaz.sty" relative to blogs/<name>/.
    # For ~/galaaz-blogs/oh_my that resolves to ~/sty/galaaz.sty.
    def install_galaaz_sty_for_blogs!(blogs_dest)
      src = File.join(root, 'sty', 'galaaz.sty')
      abort_unless(File.file?(src), "missing #{src} in gem")
      sty_dir = File.join(File.dirname(File.expand_path(blogs_dest)), 'sty')
      FileUtils.mkdir_p(sty_dir)
      dest = File.join(sty_dir, 'galaaz.sty')
      FileUtils.cp(src, dest)
      puts "galaaz sty: #{dest}"
      header = File.join(root, 'sty', 'galaaz-header.png')
      if File.file?(header)
        FileUtils.cp(header, File.join(sty_dir, 'galaaz-header.png'))
        puts "galaaz sty header: #{File.join(sty_dir, 'galaaz-header.png')}"
      end
      from_p3 = File.join(root, 'sty', 'galaaz-headers-from-p3.tex')
      if File.file?(from_p3)
        FileUtils.cp(from_p3, File.join(sty_dir, 'galaaz-headers-from-p3.tex'))
        puts "galaaz sty headers: #{File.join(sty_dir, 'galaaz-headers-from-p3.tex')}"
      end
      dest
    end

    # TinyTeX installs to ~/.TinyTeX and often ~/bin; Omarchy PATH prefers ~/.local/bin.
    def ensure_pdflatex_on_path!
      return if command_present?('pdflatex')

      candidates = Dir.glob(File.expand_path('~/.TinyTeX/bin/*/pdflatex'))
      home_bin = File.expand_path('~/bin/pdflatex')
      candidates << home_bin if File.executable?(home_bin)
      pdf = candidates.find { |p| File.executable?(p) }
      unless pdf
        warn 'galaaz add tex: pdflatex not found after TinyTeX install; check ~/.TinyTeX'
        return
      end

      local_bin = File.expand_path('~/.local/bin')
      FileUtils.mkdir_p(local_bin)
      %w[pdflatex xelatex lualatex tlmgr].each do |name|
        src = File.join(File.dirname(pdf), name)
        next unless File.executable?(src)

        link = File.join(local_bin, name)
        FileUtils.ln_sf(src, link)
      end
      puts "galaaz add tex: linked TeX tools into #{local_bin}"
    end
  end
end
