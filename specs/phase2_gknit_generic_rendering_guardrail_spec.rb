# frozen_string_literal: true

describe 'Phase 2 gknit generic rendering guardrail' do
  it 'does not contain plotting-class-specific branches in gknit engine code' do
    root = File.expand_path('..', __dir__)
    targets = [
      File.join(root, 'lib/gknit/knitr_engine.rb'),
      File.join(root, 'lib/gknit/ruby_engine.rb'),
      File.join(root, 'lib/gknit/rb_engine.rb'),
      File.join(root, 'lib/gknit/include_engine.rb')
    ]

    # Guard only executable lines (skip comments/blank lines).
    branch_tokens = [
      /if\b.*\bggplot\b/,
      /case\b.*\bggplot\b/,
      /when\b.*\bggplot\b/,
      /if\b.*\blattice\b/,
      /case\b.*\blattice\b/,
      /when\b.*\blattice\b/,
      /if\b.*\bgrid\b/,
      /case\b.*\bgrid\b/,
      /when\b.*\bgrid\b/,
      /inherits\s*\(.*["']ggplot["']/,
      /inherits\s*\(.*["']lattice["']/,
      /\bis\.ggplot\b/,
      /\bclass\s*\(.*\).*ggplot/
    ]

    hits = []

    targets.each do |path|
      File.readlines(path, chomp: true).each_with_index do |line, idx|
        stripped = line.strip
        next if stripped.empty? || stripped.start_with?('#')

        if branch_tokens.any? { |rx| stripped.match?(rx) }
          rel = path.sub("#{root}/", '')
          hits << "#{rel}:#{idx + 1}: #{stripped}"
        end
      end
    end

    expect(hits).to eq([])
  end
end
