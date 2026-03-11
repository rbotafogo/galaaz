# -*- coding: utf-8 -*-
# Specs for unboxing semantics: recurse until only Ruby values; single list → [x];
# depth limit raises UnboxDepthError. Run with: bin/run_rspec specs/unboxing_spec.rb

require 'galaaz'

describe "Unboxing (>> nil / to_ruby / unboxed_get(nil))" do

  context "single scalar (length-1 vector)" do
    it "unboxes to Ruby scalar" do
      expect(R.c(42) >> nil).to eq 42
      expect(R.c(3.14) >> nil).to eq 3.14
      expect(R.c(true) >> nil).to eq true
      expect(R.c("hello") >> nil).to eq "hello"
    end
  end

  context "single list (list of one element)" do
    it "unboxes to Array with one element" do
      lst = R.list(42)
      expect(lst >> nil).to eq [42]
    end

    it "unboxes single list with vector to [array]" do
      lst = R.list(R.c(1, 2, 3))
      expect(lst >> nil).to eq [[1, 2, 3]]
    end
  end

  context "nested list" do
    it "unboxes to nested Ruby arrays" do
      lst = R.list(R.list(1, 2), R.list(3, 4))
      expect(lst >> nil).to eq [[1, 2], [3, 4]]
    end

    it "unboxes list of list of scalar" do
      lst = R.list(R.list(10))
      expect(lst >> nil).to eq [[10]]
    end
  end

  context "list too deep" do
    it "raises R::UnboxDepthError when depth exceeds MAX_UNBOX_DEPTH" do
      deep = R.list(1)
      (R::Support::MAX_UNBOX_DEPTH - 1).times { deep = R.list(deep) }
      expect { deep >> nil }.to raise_error(R::UnboxDepthError, /list too deep/)
    end
  end
end
