# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

describe 'gknit puts formatting for R objects' do
  RMD_YAML = <<~YAML
    ---
    title: "gknit puts R objects"
    output:
      github_document: default
    ---

  YAML

  RMD_BODY = <<~RMD
    ```{ruby, echo=FALSE}
    vec = R.c(1, 2, 3, 4)
    puts "VEC_PUTS_START"
    puts vec
    puts "VEC_PUTS_END"
    print "VEC_PRINT="
    print vec
    print "\\n"
    puts "VEC_MULTI_ARG_START"
    puts "X", vec
    puts "VEC_MULTI_ARG_END"
    ```
  RMD

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

  it 'prints R vectors in R style (not one element per line)' do
    root = File.expand_path('..', __dir__)
    workdir = Dir.mktmpdir('gknit_puts_r_obj_', root)

    begin
      rmd_path = File.join(workdir, 'puts_r_object.Rmd')
      File.write(rmd_path, RMD_YAML + RMD_BODY)

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

      expect(md).to include('VEC_PUTS_START')
      expect(md).to include('VEC_PUTS_END')
      expect(md).to include('\[1\] 1 2 3 4')
      expect(md).to include('VEC_PRINT=\[1\] 1 2 3 4')
      expect(md).to include('VEC_MULTI_ARG_START')
      expect(md).to include('VEC_MULTI_ARG_END')
      expect(md).to include('X')
      expect(md).not_to include("1\n2\n3\n4")
    ensure
      FileUtils.rm_rf(workdir) if workdir && File.directory?(workdir)
    end
  end
end
