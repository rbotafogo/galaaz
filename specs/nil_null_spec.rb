# -*- coding: utf-8 -*-
# Specs for NilClass#is__null and #isTRUE (R NULL becomes Ruby nil; calling
# .is__null or .isTRUE on nil must not raise and must behave like R's is.null(NULL) / isTRUE(NULL)).
#
# Run with: bin/run_rspec specs/nil_null_spec.rb
# (bundle exec rspec needs JRUBY_OPTS=-J--add-opens=java.base/java.nio=org.apache.arrow.memory.core,ALL-UNNAMED for Arrow)

require 'galaaz'

describe "NilClass when used as R NULL (missing list element → Ruby nil)" do

  context "nil.is__null" do
    it "does not raise" do
      expect { nil.is__null }.not_to raise_error
    end

    it "returns an object that responds to unboxed_get" do
      expect(nil.is__null).to respond_to(:unboxed_get)
    end

    it "unboxed_get(0) returns true (nil is treated as null)" do
      expect(nil.is__null.unboxed_get(0)).to eq true
    end
  end

  context "nil.isTRUE" do
    it "does not raise" do
      expect { nil.isTRUE }.not_to raise_error
    end

    it "unboxed_get(0) returns false (R's isTRUE(NULL) is FALSE)" do
      expect(nil.isTRUE.unboxed_get(0)).to eq false
    end
  end

  context "nil.is__null | nil.isTRUE (as in include_engine)" do
    it "does not raise and unboxed_get(0) is true" do
      result = (nil.is__null | nil.isTRUE).unboxed_get(0)
      expect(result).to eq true
    end
  end
end
