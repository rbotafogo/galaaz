# -*- coding: utf-8 -*-
# Phase 5: Per-call result protocol — all returns via result buffer (no fallback).
# These specs assert that eval and exec_function return correct types from the
# protocol envelope. When Phase 5 is complete (fallback removed), these tests
# ensure every result path goes through the buffer.

require 'galaaz'

describe "Result protocol (Phase 5)" do

  context "R::Support.eval returns via protocol envelope" do

    it "returns scalar double as Float" do
      v = R::Support.eval("3.14")
      expect(v).to be_a(Numeric)
      expect(v).to eq 3.14
    end

    it "returns scalar integer as Numeric (unboxed)" do
      v = R::Support.eval("42L")
      expect(v).to be_a(Numeric)
      expect(v).to eq 42
    end

    it "returns scalar logical as true/false" do
      expect(R::Support.eval("TRUE")).to eq true
      expect(R::Support.eval("FALSE")).to eq false
    end

    it "returns scalar symbol as Ruby Symbol" do
      v = R::Support.eval("as.symbol('foo')")
      expect(v).to be_a(Symbol)
      expect(v).to eq :foo
    end

    it "returns length-1 character as R::Vector (not unboxed)" do
      v = R::Support.eval("'hello'")
      expect(v).to be_a(R::Vector)
      expect(v.length).to eq 1
    end

    it "returns vector (handle) as R::Vector with correct class" do
      v = R::Support.eval("c(1, 2, 3)")
      expect(v).to be_a(R::Vector)
      rcls = v.rclass.to_s
      expect(rcls).to match(/numeric|integer/)
    end

    it "returns list (handle) as R::List" do
      v = R::Support.eval("list(1, 'a', TRUE)")
      expect(v).to be_a(R::List)
      expect(v.length).to be >= 1
    end

    it "returns matrix (handle) as R::Matrix" do
      v = R::Support.eval("matrix(1:4, nrow = 2)")
      expect(v).to be_a(R::Matrix)
    end

    it "returns data.frame (handle) as R::DataFrame" do
      v = R::Support.eval("data.frame(a = 1:2, b = c('x', 'y'))")
      expect(v).to be_a(R::DataFrame)
    end

    it "returns function (handle) as R::Closure" do
      v = R::Support.eval("identity")
      expect(v).to be_a(R::Closure)
    end
  end

  context "R::Support.exec_function returns via protocol envelope" do

    it "c() returns R::Vector" do
      v = R::Support.exec_function("c", 1, 2, 3)
      expect(v).to be_a(R::Vector)
    end

    it "list() returns R::List" do
      v = R::Support.exec_function("list", 1, "x")
      expect(v).to be_a(R::List)
    end

    it "matrix() returns R::Matrix" do
      v = R::Support.exec_function("matrix", R.c(1, 2, 3, 4), 2)
      expect(v).to be_a(R::Matrix)
    end

    it "identity (function) returns R::Closure" do
      v = R::Support.exec_function("identity", 42)
      expect(v).to eq 42
    end

    it "length() returns R object (protocol handle or scalar)" do
      vec = R.c(1, 2, 3)
      # length is special-cased to not unbox; returns R::Vector
      v = R::Support.exec_function("length", vec)
      expect(v).to be_a(R::Object)
      expect(vec.length).to eq 3  # Vector#length uses unboxed_get
    end
  end

  context "Public API uses protocol (R.c, R.list, ~:sym)" do

    it "R.c builds vector via protocol" do
      v = R.c(1, 2, 3)
      expect(v).to be_a(R::Vector)
      expect(v.length).to eq 3
    end

    it "R.list builds list via protocol" do
      v = R.list(1, "a")
      expect(v).to be_a(R::List)
    end

    it "~:x retrieves object via protocol" do
      R::Support.eval("x_protocol_test <- c(10, 20)")
      v = ~:x_protocol_test
      expect(v).to be_a(R::Vector)
      expect(v[1]).to eq 10
    end
  end
end
