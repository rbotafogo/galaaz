# frozen_string_literal: true

require 'galaaz'

describe R::Device do
  it 'renders a base plot to png and writes a non-empty artifact' do
    dev = R::Device.new('png', width: 4, height: 3, dpi: 96)
    dev.open
    R.barplot(R.c(2, 5, 3, 4))
    dev.close

    path = dev.instance_variable_get(:@dev_path)
    expect(path).not_to be_nil
    expect(File.exist?(path)).to eq(true)
    expect(File.size(path)).to be > 0
  end

  it 'supports block form for svg device and writes artifact' do
    dev = R::Device.new('svg', width: 4, height: 3, dpi: 96) do
      R.plot(R.c(1, 2, 3, 4))
    end

    path = dev.instance_variable_get(:@dev_path)
    expect(path).not_to be_nil
    expect(File.exist?(path)).to eq(true)
    expect(File.size(path)).to be > 0
  end
end
