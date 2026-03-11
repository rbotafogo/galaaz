# -*- coding: utf-8 -*-
# Specs for field/component access: we use R's [[ (obj[["name"]]) instead of $
# so that atomic vectors don't trigger "$ operator is invalid for atomic vectors".
# Run with: bin/run_rspec specs/field_access_spec.rb

require 'galaaz'

describe "Field access (obj.name → R [[, not $)" do

  context "list with named elements" do
    it "returns element when accessed by method (list.fig__ext)" do
      lst = R.list(a: 1, b: 2, fig__ext: "png")
      expect(lst.fig__ext).to be_a(R::Object)
      expect(lst.fig__ext >> 0).to eq "png"
    end

    it "returns element for other names (list.a, list.b)" do
      lst = R.list(a: 10, b: 20)
      expect(lst.a >> 0).to eq 10
      expect(lst.b >> 0).to eq 20
    end
  end

  context "data frame column access" do
    it "returns column when accessed by method (df.mpg)" do
      df = ~:mtcars
      expect(df.mpg).to be_a(R::Vector)
      expect(df.mpg.length >> 0).to be >= 1
    end
  end
end
