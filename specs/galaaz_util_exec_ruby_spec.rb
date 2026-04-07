# frozen_string_literal: true

require 'galaaz'

describe GalaazUtil do
  describe RC do
    it 'normalizes R objects and arrays recursively for output' do
      rc = RC.new
      vec = R.c(1, 2, 3)
      normalized = rc.normalize_output_arg([vec, 'x', [vec]])
      expect(normalized[0]).to eq(vec.to_s)
      expect(normalized[1]).to eq('x')
      expect(normalized[2][0]).to eq(vec.to_s)
    end

    it 'tracks outputs and resets output list' do
      rc = RC.new
      rc.outputs('a')
      expect(rc.out_list).to be_a(R::List).or be_a(R::Vector)
      rc.reset_outputs
      expect(rc.out_list).to eq(nil)
      expect(rc.get_binding).to be_a(Binding)
    end
  end

  describe '.knitr_logical_trueish?' do
    let(:wrapper) do
      Struct.new(:value) do
        def unboxed_get(_idx)
          value
        end
      end
    end

    it 'treats nil and NA-like wrappers as true by default' do
      expect(GalaazUtil.knitr_logical_trueish?(nil)).to eq(true)
      expect(GalaazUtil.knitr_logical_trueish?(wrapper.new(nil))).to eq(true)
    end

    it 'handles booleans and numerics from wrappers' do
      expect(GalaazUtil.knitr_logical_trueish?(wrapper.new(true))).to eq(true)
      expect(GalaazUtil.knitr_logical_trueish?(wrapper.new(false))).to eq(false)
      expect(GalaazUtil.knitr_logical_trueish?(wrapper.new(0))).to eq(false)
      expect(GalaazUtil.knitr_logical_trueish?(wrapper.new(2))).to eq(true)
    end

    it 'handles string-like values from wrappers' do
      expect(GalaazUtil.knitr_logical_trueish?(wrapper.new('FALSE'))).to eq(false)
      expect(GalaazUtil.knitr_logical_trueish?(wrapper.new('true'))).to eq(true)
    end
  end

  describe '.knitr_option_trueish?' do
    let(:bridge) { instance_double('Bridge') }
    let(:options) { Struct.new(:r_interop).new('g2_v_opts') }

    before do
      allow(R).to receive(:bridge).and_return(bridge)
    end

    it 'returns default when options are not interop-like' do
      expect(GalaazUtil.knitr_option_trueish?(nil, 'echo', default: false)).to eq(false)
      expect(GalaazUtil.knitr_option_trueish?(Object.new, 'echo', default: true)).to eq(true)
    end

    it 'parses TRUE/FALSE and numeric tokens from R output' do
      allow(bridge).to receive(:eval_r).and_return('[1] "TRUE"', '[1] "FALSE"', '[1] "0"', '[1] "3"')
      expect(GalaazUtil.knitr_option_trueish?(options, 'echo', default: false)).to eq(true)
      expect(GalaazUtil.knitr_option_trueish?(options, 'echo', default: true)).to eq(false)
      expect(GalaazUtil.knitr_option_trueish?(options, 'echo', default: true)).to eq(false)
      expect(GalaazUtil.knitr_option_trueish?(options, 'echo', default: false)).to eq(true)
    end

    it 'falls back to default for NA/NULL/empty or bridge errors' do
      allow(bridge).to receive(:eval_r).and_return('[1] "NA"', '[1] "NULL"', '')
      expect(GalaazUtil.knitr_option_trueish?(options, 'echo', default: false)).to eq(false)
      expect(GalaazUtil.knitr_option_trueish?(options, 'echo', default: true)).to eq(true)
      expect(GalaazUtil.knitr_option_trueish?(options, 'echo', default: false)).to eq(false)

      allow(bridge).to receive(:eval_r).and_raise(StandardError, 'bridge down')
      expect(GalaazUtil.knitr_option_trueish?(options, 'echo', default: true)).to eq(true)
    end
  end
end

