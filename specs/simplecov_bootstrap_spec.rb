describe 'SimpleCov bootstrap' do
  it 'loads SimpleCov when available' do
    if Gem.loaded_specs.key?('simplecov')
      expect(defined?(SimpleCov)).to eq('constant')
      expect(SimpleCov.running).to eq(true)
    else
      skip('simplecov gem is not available in this environment')
    end
  end
end
