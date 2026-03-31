# frozen_string_literal: true

require 'open3'

describe 'gknit CLI option parsing' do
  it 'accepts options when they appear before filename' do
    stdout, stderr, status = Open3.capture3(
      'ruby', 'bin/gknit', '--callback_timeout_ms', 'not_an_integer', 'specs/does_not_exist.Rmd'
    )

    expect(status.success?).to eq(false)
    expect("#{stdout}\n#{stderr}").to include('invalid argument: --callback_timeout_ms')
  end

  it 'accepts options when they appear after filename' do
    stdout, stderr, status = Open3.capture3(
      'ruby', 'bin/gknit', 'specs/does_not_exist.Rmd',
      '--callback_timeout_ms', 'not_an_integer'
    )

    expect(status.success?).to eq(false)
    expect("#{stdout}\n#{stderr}").to include('invalid argument: --callback_timeout_ms')
  end
end
