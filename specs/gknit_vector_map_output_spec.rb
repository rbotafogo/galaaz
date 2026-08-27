# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

describe 'gknit vector map output' do
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

  it 'renders vec.map in ruby chunks without missing bridge methods' do
    root = File.expand_path('..', __dir__)
    workdir = Dir.mktmpdir('gknit_vec_map_', root)

    begin
      rmd_path = File.join(workdir, 'vector_map.Rmd')
      File.write(rmd_path, <<~RMD)
        ---
        title: "gknit vector map"
        output:
          github_document: default
        ---

        ```{ruby, echo=FALSE}
        vec = R.c(1, 2, 3, 4)
        puts vec.map { |x| x + 2 }
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

      expect(md).to include('\\[1\\] 3 4 5 6')
      expect(md).not_to include("undefined method 'push_double_vector'")
    ensure
      FileUtils.rm_rf(workdir) if workdir && File.directory?(workdir)
    end
  end
end
