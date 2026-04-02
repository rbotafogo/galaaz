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
    {
      'JAVA_OPTS' => '--add-opens=java.base/java.nio=ALL-UNNAMED',
      'PATH' => path
    }
  end

  it 'continues processing and prints timeout in final report' do
    skip('Temporarily skipped: installation timeout behavior will be reviewed in a dedicated pass')
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
        R.bridge.eval_r("install.packages <- function(...) { Sys.sleep(2); invisible(NULL) }")
        ```

        ```{ruby timeout_install}
        R.install_and_loads('definitely_fake_pkg_for_timeout_spec')
        ```

        ```{ruby after_timeout}
        puts "AFTER_TIMEOUT_CHUNK_OK"
        ```
      RMD

      rel_rmd = File.basename(workdir) + '/' + File.basename(rmd_path)
      out, err, st = Open3.capture3(
        self.class.gknit_env,
        'bin/gknit', '--output_format', 'github_document', '--bridge_timeout_sec', '1', rel_rmd,
        chdir: root
      )

      md_path = File.join(workdir, 'install_timeout.md')
      expect(st.success?).to be(true)
      expect(File.exist?(md_path)).to be(true)
      md = File.read(md_path)
      expect(md).to include('AFTER_TIMEOUT_CHUNK_OK')
      expect(err).to include('gknit internal errors detected:')
      expect(err).to include('chunk=timeout_install')
      expect(err).to include('no RET for')
      expect(out).not_to be_nil
    ensure
      FileUtils.rm_rf(workdir) if workdir && File.directory?(workdir)
    end
  end
end
