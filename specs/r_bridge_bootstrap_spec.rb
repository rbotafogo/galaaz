require 'galaaz'

describe 'R bridge bootstrap' do
  it 'uses NewBridge adapter' do
    expect(R.bridge).to be_a(R::NewBridgeAdapter)
  end

  it 'does not expose shadow bridge selector API' do
    expect(R.respond_to?(:shadow_bridge_selected?)).to eq(false)
  end
end
