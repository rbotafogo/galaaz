# -*- coding: utf-8 -*-
# Scalar character result protocol: when R sends a length-1 character (type 3),
# the bridge unescapes so Ruby receives real newlines and double quotes
# (e.g. \n -> newline, \" -> ", \\ -> \). This avoids SyntaxError when chunk
# code is round-tripped (e.g. gknit exec_ruby).
# Run with: bin/run_rspec specs/scalar_character_spec.rb

require 'galaaz'

describe "Scalar character (result protocol unescaping)" do

  context "R -> Ruby: literal \\n and \" in string" do
    # R string "a\\nb" has chars: a, backslash, n, b. Bridge unescapes \n -> newline.
    it "unescapes \\n to real newline when unboxing length-1 character" do
      v = R::Support.eval('"a\\\\nb"')
      expect(v).to be_a(R::Object)
      s = v >> 0
      expect(s).to eq "a\nb"
    end

    # R string "a\\\"b" has chars: a, backslash, double-quote, b. Bridge unescapes \" -> ".
    it "unescapes \\\" to real double-quote when unboxing length-1 character" do
      v = R::Support.eval('"a\\\\\\"b"')
      expect(v).to be_a(R::Object)
      s = v >> 0
      expect(s).to eq 'a"b'
    end

    it "unescapes both \\n and \\\" in one string" do
      # R string with a, \n, b, \", c -> Ruby "a\nb\"c"
      v = R::Support.eval('"a\\\\nb\\\\\\"c"')
      expect(v).to be_a(R::Object)
      s = v >> 0
      expect(s).to eq "a\nb\"c"
    end
  end

  context "plain strings unchanged" do
    it "leaves strings without backslash escapes unchanged" do
      v = R::Support.eval('"hello"')
      expect((v >> 0)).to eq "hello"
    end
  end
end
