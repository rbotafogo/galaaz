# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'

describe 'Phase 3 gknit generic graphics capture' do
  def render_github_doc(input_path, output_filename = 'rendered.md')
    root = File.expand_path('..', __dir__)
    rel_input = input_path.sub("#{root}/", '')
    cmd = ['bin/gknit', '-f', rel_input, '--output_format', 'github_document', '-o', output_filename]
    Open3.capture3(*cmd, chdir: root)
  end

  it 'captures and includes base/grid/ggplot figures generically' do
    root = File.expand_path('..', __dir__)
    tmp_root = File.join(root, 'tmp')
    FileUtils.mkdir_p(tmp_root)
    work = Dir.mktmpdir('gknit_phase3_graphics_', tmp_root)
    input = File.join(work, 'fixture.Rmd')
    output = File.join(work, 'rendered.md')

    begin
      File.write(input, <<~RMD)
        ---
        title: "phase3-generic-graphics"
        output:
          github_document: default
        ---

        This document mixes multiple graphics systems.

        ```{ruby, echo=FALSE, eval=TRUE, include=TRUE}
        R.plot(R.c(1, 2, 3), R.c(1, 4, 9), type: "b")
        ```

        ```{ruby, echo=FALSE, eval=TRUE, include=TRUE}
        R::Support.eval("grid::grid.newpage(); grid::grid.rect(gp = grid::gpar(fill='grey85'))")
        ```

        ```{ruby, echo=FALSE, eval=TRUE, include=TRUE}
        unless R::Support.eval("requireNamespace('ggplot2', quietly=TRUE)") == true
          raise "ggplot2 is not available"
        end
        R::Support.eval("p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point(); print(p)")
        ```
      RMD

      stdout, stderr, status = render_github_doc(input)
      expect(status.success?).to eq(true), "gknit failed:\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
      expect(File.exist?(output)).to eq(true)

      md = File.read(output)
      expect(md).to include('phase3-generic-graphics')
      expect(stderr).not_to include('ggplot2 is not available')
      fig_dir = File.join(work, 'rendered_files', 'figure-gfm')
      expect(File.directory?(fig_dir)).to eq(true)

      # gknit/github_document should emit markdown image markup so pandoc can
      # render figures consistently across output formats.
      image_paths = md.scan(%r{!\[\]\((rendered_files/figure-gfm/[^\)]+)\)}).flatten
      expect(image_paths.length).to be >= 3
      image_paths.each do |rel|
        rel = rel.sub(%r{^\./}, '')
        expect(File.exist?(File.join(work, rel))).to eq(true), "missing figure artifact: #{rel}"
      end
    ensure
      FileUtils.rm_rf(work) if work && File.directory?(work)
    end
  end
end
