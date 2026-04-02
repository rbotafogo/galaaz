# frozen_string_literal: true

# Phase 2 (performance): Object.build prefers wrapper_tag / r_class; class() probe only as fallback.

require 'galaaz'

describe 'R::Object.build (Phase 2 — envelope metadata vs class probe)' do
  describe '.build_class_probe_count' do
    it 'does not probe when r_class and wrapper_tag come from eval_r_with_result envelope' do
      vn = R::Support.generate_var_name
      env = R.bridge.eval_r_with_result("#{vn} <- c(1L, 2L, 3L)")
      expect(env[:type]).to eq(:handle)
      expect(env[:wrapper_tag]).to eq('vector')

      R::Object.reset_build_counters!
      obj = R::Object.build(env[:handle], nil, r_class: env[:r_class], wrapper_tag: env[:wrapper_tag])
      expect(obj).to be_a(R::Vector)
      expect(R::Object.build_class_probe_count).to eq(0)
    end

    it 'does not probe when only r_class is set (legacy envelope)' do
      vn = R::Support.generate_var_name
      env = R.bridge.eval_r_with_result("#{vn} <- list(a = 1L)")
      expect(env[:type]).to eq(:handle)

      R::Object.reset_build_counters!
      obj = R::Object.build(env[:handle], nil, r_class: env[:r_class], wrapper_tag: nil)
      expect(obj).to be_a(R::List)
      expect(R::Object.build_class_probe_count).to eq(0)
    end

    it 'probes once when neither r_class nor a non-other wrapper_tag is given' do
      vn = R::Support.generate_var_name
      R.bridge.eval_r("#{vn} <- c(10L, 20L)")

      R::Object.reset_build_counters!
      obj = R::Object.build(vn)
      expect(obj).to be_a(R::Vector)
      expect(R::Object.build_class_probe_count).to eq(1)
    end

    it 'uses r_class for wrapper_tag other without probing (e.g. expression)' do
      vn = R::Support.generate_var_name
      env = R.bridge.eval_r_with_result("#{vn} <- expression(1 + 2)")
      expect(env[:wrapper_tag]).to eq('other')

      R::Object.reset_build_counters!
      obj = R::Object.build(vn, nil, r_class: env[:r_class], wrapper_tag: env[:wrapper_tag])
      expect(obj).to be_a(R::RExpression)
      expect(R::Object.build_class_probe_count).to eq(0)
    end
  end
end
