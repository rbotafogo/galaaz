# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'

describe 'Phase 2 gknit raw code leakage' do
  it 'does not leak unevaluated ruby source when echo is FALSE' do
    root = File.expand_path('..', __dir__)
    tmp_root = File.join(root, 'tmp')
    FileUtils.mkdir_p(tmp_root)
    work = Dir.mktmpdir('gknit_phase2_no_leak_', tmp_root)
    input = File.join(work, 'fixture.Rmd')
    output = File.join(work, 'rendered.md')

    File.write(input, <<~RMD)
      ---
      title: "phase2-no-leak"
      output:
        github_document: default
      ---

      ```{ruby, echo=FALSE, eval=TRUE, include=TRUE}
      leak_source_line = "PHASE2_RAW_SOURCE_SHOULD_NOT_LEAK"
      puts "PHASE2_EVALUATED_OUTPUT_OK"
      ```
    RMD

    begin
      rel_input = input.sub("#{root}/", '')
      cmd = ['bin/gknit', '-f', rel_input, '--output_format', 'github_document', '-o', 'rendered.md']
      stdout, stderr, status = Open3.capture3(*cmd, chdir: root)
      expect(status.success?).to eq(true), "gknit failed:\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"

      rendered = File.read(output)
      expect(rendered).to include('PHASE2_EVALUATED_OUTPUT_OK')
      expect(rendered).not_to include('PHASE2_RAW_SOURCE_SHOULD_NOT_LEAK')
      expect(rendered).not_to include('leak_source_line =')
    ensure
      FileUtils.rm_rf(work) if work && File.directory?(work)
    end
  end
end
