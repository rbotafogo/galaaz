# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

describe 'gknit install timeout reporting' do
  def self.gknit_env
    home = Dir.home
    extra = [
      File.join(home, 'bin'),
      File.join(home, '.TinyTeX', 'bin')
    ].select { |dir| File.directory?(dir) }
    path = ENV.fetch('PATH', '')
    path = ([*extra, path].join(File::PATH_SEPARATOR)) unless extra.empty?
    ENV.to_h.merge(
      'JAVA_OPTS' => '--add-opens=java.base/java.nio=ALL-UNNAMED',
      'PATH' => path,
      # Job await limit (bridge --bridge_timeout_sec no longer drives CRAN installs).
      'GALAAZ_INSTALL_TIMEOUT_SEC' => '1'
    )
  end

  it 'continues processing and prints timeout in final report' do
    root = File.expand_path('..', __dir__)
    workdir = Dir.mktmpdir('gknit_install_timeout_', root)

    begin
      rmd_path = File.join(workdir, 'install_timeout.Rmd')
      File.write(rmd_path, <<~RMD)
        ---
        title: "install timeout"
        output:
          github_document: default
        ---

        ```{ruby setup_stub}
        # Deterministic slow "install": child Rscript sleeps instead of CRAN work.
        # Use ::R — bare R in chunks is RC::R (gknit scope), not the Galaaz module.
        module ::R
          class Job
            def self.install(*packages, lib_dir: default_lib_dir, repos: DEFAULT_REPOS, wait: true, timeout: nil, &block)
              pkgs = packages.flatten.map(&:to_s).reject(&:empty?)
              raise ArgumentError, 'R::Job.install requires at least one package name' if pkgs.empty?

              FileUtils.mkdir_p(lib_dir)
              FileUtils.mkdir_p(jobs_root)
              with_install_lock do
                job = new(kind: 'install', packages: pkgs, lib_dir: lib_dir)
                job.send(:spawn_eval!, 'Sys.sleep(30)')
                finish_job(job, wait: wait, timeout: timeout, &block)
              end
            end
          end
        end
        ```

        ```{ruby timeout_install}
        ::R.install_and_loads('definitely_fake_pkg_for_timeout_spec')
        ```

        ```{ruby after_timeout}
        puts "AFTER_TIMEOUT_CHUNK_OK"
        ```
      RMD

      rel_rmd = File.basename(workdir) + '/' + File.basename(rmd_path)
      out, err, st = Open3.capture3(
        self.class.gknit_env,
        'bin/gknit', '--output_format', 'github_document',
        '--install_timeout_sec', '1',
        rel_rmd,
        chdir: root
      )

      md_path = File.join(workdir, 'install_timeout.md')
      expect(st.success?).to be(true), "gknit failed (status=#{st.exitstatus}):\n#{err}\n#{out}"
      expect(File.exist?(md_path)).to be(true)
      md = File.read(md_path)
      expect(md).to include('AFTER_TIMEOUT_CHUNK_OK')
      expect(err).to include('gknit internal errors detected:')
      expect(err).to include('chunk=timeout_install')
      expect(err).to match(/install job timed out/i)
      expect(out).not_to be_nil
    ensure
      FileUtils.rm_rf(workdir) if workdir && File.directory?(workdir)
    end
  end
end
