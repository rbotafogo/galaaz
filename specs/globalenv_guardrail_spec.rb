# frozen_string_literal: true

require 'pathname'

describe 'GlobalEnv mutable write guardrail' do
  it 'does not introduce unapproved .GlobalEnv$... <- writes in active bridge path' do
    root = Pathname.new(__dir__).join('..').expand_path

    # Intentionally scoped to active lib paths (ShadowBridge excluded as obsolete).
    scoped_files = Dir[root.join('lib/**/*.rb').to_s].reject { |p| p.end_with?('lib/R_interface/shadow_bridge.rb') }

    allow_by_file = {
      'lib/R_interface/rdevice.rb' => [
        /\.GlobalEnv\$evaluate_plot_snapshot <- function\(\)/,
        /\.GlobalEnv\$galaaz_save_plot <- function\(path, dev_type, width, height, dpi\)/
      ],
      'lib/gknit/knitr_engine.rb' => [
        /\.GlobalEnv\$knitr_dev2ext <- function\(x\)/,
        /\.GlobalEnv\$g_simpleMessage <- function\(message\)/,
        /\.GlobalEnv\$g_simpleWarning <- function\(message\)/,
        /\.GlobalEnv\$evaluate_plot_snapshot <- function\(\)/,
        /\.GlobalEnv\$save_recorded_plot <- function\(path, plot, width, height, dev, res, units\)/,
        /\.GlobalEnv\$knitr_wrap <- function\(x, options\)/,
        /\.GlobalEnv\$showtext <- function\(\)/
      ],
      'lib/R_interface/rsupport.rb' => [
        /assignment = "\.GlobalEnv\$\#\{var_name\} <- \{ \#\{final_r_code\}\\n \}"/,
        /R\.bridge\.eval_r\("\.GlobalEnv\$\#\{var\} <- \#\{rhs\}"\)/
      ],
      'lib/R_interface/robject.rb' => [
        /assignment = "\.GlobalEnv\$\#\{var\} <- \#\{r_code\}"/
      ],
      'lib/R_interface/rvector.rb' => [
        /assignment = "\.GlobalEnv\$\#\{var_name\} <- \#\{@r_interop\}\[\[\#\{idx \+ 1\}\]\]"/
      ]
    }

    violations = []

    scoped_files.each do |file|
      rel = Pathname.new(file).relative_path_from(root).to_s
      lines = File.readlines(file, chomp: true)
      lines.each_with_index do |line, idx|
        next unless line.match?(/\.GlobalEnv\$.*<-/)

        allowed = allow_by_file.fetch(rel, []).any? { |rx| line.match?(rx) }
        violations << "#{rel}:#{idx + 1}: #{line.strip}" unless allowed
      end
    end

    expect(violations).to eq([])
  end
end
