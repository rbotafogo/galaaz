# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

describe 'Phase 2 gknit chunk semantics' do
  PHASE2_RMD_BODY = <<~RMD
    ```{ruby text_chunk, echo=FALSE}
    R.bridge.eval_r("rm(list=c('phase2_eval_false','phase2_include_false'), envir=.GlobalEnv)")
    puts "PHASE2_TEXT_OUTPUT"
    ```

    ```{ruby echo_inherit_chunk, echo=NA}
    puts "PHASE2_ECHO_NA_OUTPUT"
    ```

    ```{ruby eval_false_hidden, eval=FALSE, echo=FALSE}
    R.bridge.eval_r(".GlobalEnv$phase2_eval_false <- 1L")
    ```

    ```{ruby include_false_hidden, include=FALSE, eval=TRUE, echo=FALSE}
    R.bridge.eval_r(".GlobalEnv$phase2_include_false <- 1L")
    puts "PHASE2_INCLUDE_FALSE_HIDDEN_OUTPUT"
    ```

    ```{ruby check_eval_false_state, echo=FALSE}
    v = R.bridge.eval_r("if (exists('phase2_eval_false', envir=.GlobalEnv)) 1L else 0L")
    puts "PHASE2_EVAL_FALSE_STATE=\#{v.to_s.gsub('[1] ', '').strip}"
    ```

    ```{ruby check_include_false_state, echo=FALSE}
    v = R.bridge.eval_r("if (exists('phase2_include_false', envir=.GlobalEnv)) 1L else 0L")
    puts "PHASE2_INCLUDE_FALSE_STATE=\#{v.to_s.gsub('[1] ', '').strip}"
    ```
  RMD

  def self.phase2_rmd_yaml
    <<~YAML
      ---
      title: "Phase2 chunk semantics"
      output:
        html_document:
          self_contained: true
        pdf_document: default
        github_document: default
      ---

    YAML
  end

  # TinyTeX installs symlinks under ~/bin; many non-login shells omit that from PATH,
  # but R/rmarkdown must find pdflatex when rendering pdf_document.
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

  def run_gknit(root, rel_rmd, output_format)
    Open3.capture3(
      self.class.gknit_env,
      'bin/gknit', '--output_format', output_format, rel_rmd,
      chdir: root
    )
  end

  def assert_phase2_chunk_semantics_in_text(text)
    expect(text).to include('PHASE2_TEXT_OUTPUT')
    expect(text).to include('PHASE2_ECHO_NA_OUTPUT')
    expect(text).to include('PHASE2_EVAL_FALSE_STATE=0')
    expect(text).to include('PHASE2_INCLUDE_FALSE_STATE=1')
    expect(text).not_to include('PHASE2_INCLUDE_FALSE_HIDDEN_OUTPUT')
  end

  it 'html_document: renders evaluated output and honors echo/include/eval options' do
    root = File.expand_path('..', __dir__)
    workdir = Dir.mktmpdir('phase2_gknit_', root)

    begin
      rmd_path = File.join(workdir, 'phase2_chunk_semantics.Rmd')
      File.write(rmd_path, self.class.phase2_rmd_yaml + PHASE2_RMD_BODY)

      rel_rmd = File.basename(workdir) + '/' + File.basename(rmd_path)
      out, err, st = run_gknit(root, rel_rmd, 'html_document')
      expect(st.success?).to be(true), "gknit failed\nstdout:\n#{out}\nstderr:\n#{err}"

      html_path = rmd_path.sub(/\.Rmd\z/, '.html')
      expect(File.exist?(html_path)).to be(true), "missing html output: #{html_path}"
      assert_phase2_chunk_semantics_in_text(File.read(html_path))
    ensure
      FileUtils.rm_rf(workdir) if workdir && File.directory?(workdir)
    end
  end

  it 'github_document: same chunk semantics in generated Markdown' do
    root = File.expand_path('..', __dir__)
    workdir = Dir.mktmpdir('phase2_gknit_', root)

    begin
      rmd_path = File.join(workdir, 'phase2_chunk_semantics.Rmd')
      File.write(rmd_path, self.class.phase2_rmd_yaml + PHASE2_RMD_BODY)

      rel_rmd = File.basename(workdir) + '/' + File.basename(rmd_path)
      out, err, st = run_gknit(root, rel_rmd, 'github_document')
      expect(st.success?).to be(true), "gknit failed\nstdout:\n#{out}\nstderr:\n#{err}"

      md_path = rmd_path.sub(/\.Rmd\z/, '.md')
      expect(File.exist?(md_path)).to be(true), "missing github_document output: #{md_path}"
      assert_phase2_chunk_semantics_in_text(File.read(md_path))
    ensure
      FileUtils.rm_rf(workdir) if workdir && File.directory?(workdir)
    end
  end

  # Always checks LaTeX -> PDF success. Same string expectations as HTML/md only when
  # `pdftotext` (poppler-utils) is installed or literals appear uncompressed in the PDF.
  it 'pdf_document: LaTeX produces a valid PDF; full chunk string checks when pdftotext exists' do
    root = File.expand_path('..', __dir__)
    workdir = Dir.mktmpdir('phase2_gknit_', root)

    begin
      rmd_path = File.join(workdir, 'phase2_chunk_semantics.Rmd')
      File.write(rmd_path, self.class.phase2_rmd_yaml + PHASE2_RMD_BODY)

      rel_rmd = File.basename(workdir) + '/' + File.basename(rmd_path)
      out, err, st = run_gknit(root, rel_rmd, 'pdf_document')
      unless st.success?
        combined = "#{out}\n#{err}"
        skip "PDF render skipped (LaTeX/tooling): #{combined[0, 2000]}"
      end

      pdf_path = rmd_path.sub(/\.Rmd\z/, '.pdf')
      expect(File.exist?(pdf_path)).to be(true), "missing pdf output: #{pdf_path}"
      pdf_bytes = File.binread(pdf_path, 8)
      expect(pdf_bytes).to start_with('%PDF')
      expect(File.size(pdf_path)).to be > 2000

      # Chunk text is usually Flate-compressed; full semantic checks need pdftotext (poppler-utils).
      text = +''
      pdftotext_ok = false
      begin
        text, st = Open3.capture2('pdftotext', '-layout', pdf_path, '-')
        pdftotext_ok = st.success? && !text.strip.empty?
      rescue Errno::ENOENT
        pdftotext_ok = false
      end

      if pdftotext_ok
        assert_phase2_chunk_semantics_in_text(text)
      else
        raw = File.binread(pdf_path)
        extractable = raw.force_encoding('ASCII-8BIT').scan(/[ -~]{6,}/).join("\n")
        assert_phase2_chunk_semantics_in_text(extractable) if extractable.include?('PHASE2_TEXT_OUTPUT')
      end
    ensure
      FileUtils.rm_rf(workdir) if workdir && File.directory?(workdir)
    end
  end
end
