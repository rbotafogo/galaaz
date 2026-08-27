# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

describe 'gknit internal error report' do
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
      'PATH' => path
    )
  end

  it 'prints chunk-scoped report only when internal errors are detected' do
    root = File.expand_path('..', __dir__)
    workdir = Dir.mktmpdir('gknit_internal_report_', root)

    begin
      rmd_path = File.join(workdir, 'internal_error.Rmd')
      File.write(rmd_path, <<~RMD)
        ---
        title: "internal report"
        output:
          github_document: default
        ---

        ```{ruby bad_dev, dev='tiff'}
        puts "x"
        ```
      RMD

      rel_rmd = File.basename(workdir) + '/' + File.basename(rmd_path)
      _out, err, st = Open3.capture3(
        self.class.gknit_env,
        'bin/gknit', '--output_format', 'github_document', rel_rmd,
        chdir: root
      )

      # Chunk-level errors are rendered inline; gknit process should still succeed.
      expect(st.success?).to be(true)
      expect(err).to include('gknit internal errors detected:')
      expect(err).to include('chunk=bad_dev')
      expect(err).to include('Unsupported graphics device')
    ensure
      FileUtils.rm_rf(workdir) if workdir && File.directory?(workdir)
    end
  end
end

