# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

describe 'gknit include engine' do
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

  it 'loads include file code so constants are available in following ruby chunks' do
    root = File.expand_path('..', __dir__)
    workdir = Dir.mktmpdir('gknit_include_engine_', root)

    begin
      model_rb = File.join(workdir, 'model.rb')
      File.write(model_rb, <<~RUBY)
        class Model
          def answer
            42
          end
        end
      RUBY

      rmd_path = File.join(workdir, 'include_model.Rmd')
      File.write(rmd_path, <<~RMD)
        ---
        title: "include engine spec"
        output:
          github_document: default
        ---

        ```{include model}
        ```

        ```{ruby, echo=FALSE}
        m = Model.new
        puts m.answer
        ```
      RMD

      rel_rmd = File.basename(workdir) + '/' + File.basename(rmd_path)
      out, err, st = Open3.capture3(
        self.class.gknit_env,
        'bin/gknit', '--output_format', 'github_document', rel_rmd,
        chdir: root
      )
      expect(st.success?).to be(true), "gknit failed\nstdout:\n#{out}\nstderr:\n#{err}"

      md_path = rmd_path.sub(/\.Rmd\z/, '.md')
      expect(File.exist?(md_path)).to be(true), "missing markdown output: #{md_path}"
      md = File.read(md_path)

      expect(md).to include('42')
      expect(md).not_to include('uninitialized constant RC::Model')
      expect(md).not_to include('Include failed:')
    ensure
      FileUtils.rm_rf(workdir) if workdir && File.directory?(workdir)
    end
  end
end
