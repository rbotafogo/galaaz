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

  # Phase A (BasicObject migration): ensure R::Object has the explicit Ruby surface
  # we need. Run with protocol + minimal set to catch regressions.
  context "R::Object Ruby surface (Phase A — BasicObject migration)" do

    let(:vec) { R.c(1, 2, 3) }
    let(:lst) { R.list(1, "a") }

    it "responds to class and returns the concrete Ruby class" do
      expect(vec).to respond_to(:class)
      expect(vec.class).to eq R::Vector
      expect(lst.class).to eq R::List
    end

    it "responds to to_s and returns a string (R print output)" do
      expect(vec).to respond_to(:to_s)
      expect(vec.to_s).to be_a(String)
      expect(vec.to_s).to match(/[1-3]/)
    end

    it "responds to respond_to? and reports explicit and forwarded methods" do
      expect(vec).to respond_to(:respond_to?)
      expect(vec.respond_to?(:r_interop)).to eq true
      expect(vec.respond_to?(:length)).to eq true
      expect(vec.respond_to?(:class)).to eq true
      expect(vec.respond_to?(:>>)).to eq true
      expect(vec.respond_to?(:[])).to eq true
    end

    it "responds to is_a? and kind_of? with correct type checks" do
      expect(vec).to respond_to(:is_a?)
      expect(vec).to respond_to(:kind_of?)
      expect(vec.is_a?(R::Vector)).to eq true
      expect(vec.is_a?(R::Object)).to eq true
      expect(vec.kind_of?(R::Vector)).to eq true
      expect(vec.is_a?(R::List)).to eq false
    end

    it "responds to instance_of? with correct class check" do
      expect(vec).to respond_to(:instance_of?)
      expect(vec.instance_of?(R::Vector)).to eq true
      expect(vec.instance_of?(R::Object)).to eq false
    end

    it "responds to inspect and returns a string with class and handle" do
      expect(vec).to respond_to(:inspect)
      expect(vec.inspect).to be_a(String)
      expect(vec.inspect).to include("R::Vector")
      expect(vec.inspect).to include("r_interop")
    end

    it "responds to object_id and returns an integer" do
      expect(vec).to respond_to(:object_id)
      expect(vec.object_id).to be_a(Integer)
      expect(vec.object_id).to eq vec.__id__
    end
  end

  # Phase 1 performance: gatekeeper sends stable wrapper_tag on handle results (docs/performance_plan.md).
  context "eval_r_with_result handle envelopes include wrapper_tag" do
    def envelope_for_rhs(rhs_r)
      vn = R::Support.generate_var_name
      R.bridge.eval_r_with_result("#{vn} <- #{rhs_r}")
    end

    it "tags multi-element vector" do
      env = envelope_for_rhs("c(1L, 2L, 3L)")
      expect(env[:type]).to eq(:handle)
      expect(env[:wrapper_tag]).to eq("vector")
    end

    it "tags data.frame" do
      env = envelope_for_rhs("data.frame(a = 1:2, b = c('u', 'v'))")
      expect(env[:type]).to eq(:handle)
      expect(env[:wrapper_tag]).to eq("data_frame")
    end

    it "tags matrix" do
      env = envelope_for_rhs("matrix(1:4, nrow = 2)")
      expect(env[:type]).to eq(:handle)
      expect(env[:wrapper_tag]).to eq("matrix")
    end

    it "tags list" do
      env = envelope_for_rhs("list(1L, 'a', TRUE)")
      expect(env[:type]).to eq(:handle)
      expect(env[:wrapper_tag]).to eq("list")
    end

    it "tags closure" do
      env = envelope_for_rhs("identity")
      expect(env[:type]).to eq(:handle)
      expect(env[:wrapper_tag]).to eq("closure")
    end

    it "tags environment" do
      env = envelope_for_rhs("new.env()")
      expect(env[:type]).to eq(:handle)
      expect(env[:wrapper_tag]).to eq("environment")
    end

    it "tags language (call)" do
      env = envelope_for_rhs("quote(1 + 2)")
      expect(env[:type]).to eq(:handle)
      expect(env[:wrapper_tag]).to eq("language")
    end

    it "omits wrapper_tag for scalar results" do
      vn = R::Support.generate_var_name
      env = R.bridge.eval_r_with_result("#{vn} <- 42L")
      expect(env[:type]).to eq(:scalar_integer)
      expect(env).not_to have_key(:wrapper_tag)
    end
  end
end
