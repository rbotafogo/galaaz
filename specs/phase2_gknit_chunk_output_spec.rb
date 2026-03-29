# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

describe 'Phase 2 gknit chunk semantics' do
  it 'renders evaluated output and honors echo/include/eval options' do
    root = File.expand_path('..', __dir__)
    workdir = Dir.mktmpdir('phase2_gknit_', root)

    rmd_path = File.join(workdir, 'phase2_chunk_semantics.Rmd')
    File.write(rmd_path, <<~RMD)
      ---
      title: "Phase2 chunk semantics"
      output:
        html_document:
          self_contained: true
      ---

      ```{ruby text_chunk, echo=FALSE}
      puts "PHASE2_TEXT_OUTPUT"
      ```

      ```{ruby echo_inherit_chunk, echo=NA}
      puts "PHASE2_ECHO_NA_OUTPUT"
      ```

      ```{ruby eval_false_hidden, eval=FALSE, echo=FALSE}
      $phase2_eval_false = "set_by_eval_false"
      ```

      ```{ruby include_false_hidden, include=FALSE, eval=TRUE, echo=FALSE}
      $phase2_include_false = "set_by_include_false"
      puts "PHASE2_INCLUDE_FALSE_HIDDEN_OUTPUT"
      ```

      ```{ruby check_eval_false_state, echo=FALSE}
      puts "PHASE2_EVAL_FALSE_STATE=#{defined?($phase2_eval_false) ? $phase2_eval_false : 'nil'}"
      ```

      ```{ruby check_include_false_state, echo=FALSE}
      puts "PHASE2_INCLUDE_FALSE_STATE=#{defined?($phase2_include_false) ? $phase2_include_false : 'nil'}"
      ```
    RMD

    env = { 'JAVA_OPTS' => '--add-opens=java.base/java.nio=ALL-UNNAMED' }
    rel_rmd = File.basename(workdir) + '/' + File.basename(rmd_path)
    out, err, st = Open3.capture3(env, 'bin/gknit', rel_rmd, chdir: root)
    expect(st.success?).to be(true), "gknit failed\nstdout:\n#{out}\nstderr:\n#{err}"

    html_path = rmd_path.sub(/\.Rmd\z/, '.html')
    expect(File.exist?(html_path)).to be(true), "missing html output: #{html_path}"
    html = File.read(html_path)

    # Evaluated text output should be rendered.
    expect(html).to include('PHASE2_TEXT_OUTPUT')
    # echo=NA should inherit default (TRUE) and keep source code visible.
    expect(html).to include('PHASE2_ECHO_NA_OUTPUT')
    # eval=FALSE + echo=FALSE should not execute the assignment.
    expect(html).to include('PHASE2_EVAL_FALSE_STATE=nil')
    # Current custom engine behavior: include=FALSE chunk output is hidden, and assignment does not persist.
    # Keep this assertion to lock current behavior; if we change to strict knitr semantics, discuss first.
    expect(html).to include('PHASE2_INCLUDE_FALSE_STATE=nil')
    expect(html).not_to include('PHASE2_INCLUDE_FALSE_HIDDEN_OUTPUT')
  end
end
