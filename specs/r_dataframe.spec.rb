# -*- coding: utf-8 -*-

##########################################################################################
# @author Rodrigo Botafogo
#
# Copyright © 2018 Rodrigo Botafogo. All Rights Reserved. Permission to use, copy, modify, 
# and distribute this software and its documentation, without fee and without a signed 
# licensing agreement, is hereby granted, provided that the above copyright notice, this 
# paragraph and the following two paragraphs appear in all copies, modifications, and 
# distributions.
#
# IN NO EVENT SHALL RODRIGO BOTAFOGO BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, 
# INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF 
# THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RODRIGO BOTAFOGO HAS BEEN ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#
# RODRIGO BOTAFOGO SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE 
# SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED HEREUNDER IS PROVIDED "AS IS". 
# RODRIGO BOTAFOGO HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, 
# OR MODIFICATIONS.
##########################################################################################

require '../config'
require 'cantata'

describe R::DataFrame do

  #----------------------------------------------------------------------------------------
  context "Create DataFrame" do

    it "should create a dataframe from a vector" do
      vec = R.seq(6)
      vec.dim = R.c(2, 3)
      
      # create a DataFrame from a vector
      df = R.as__data__frame(vec)
      expect(df[1, "V1"]).to eq 1
      # expect(df[:all, "V1"].identical(R.c(1, 2))).to eq true
      # expect(df[1, :all].identical(R.c(V1: 1, V2: 3, V3: 5))).to eq true
      
      # df[:all, "V1"].pp
      df[1, :all].pp
      vec = R.c(V1: 1, V2: 3, V3: 5)
      vec.dim = R.c(1, 3)
      vec.pp
      
      # df["V2"].pp
      # df["V3"].pp
      
      # df["V2"].pp
      # df["V3"].pp

    end

    it "should accept the use of the apply family of functions" do
      # unlist(lapply(mtcars, class))
      # R.mtcars.lapply(R.rclass).unlist.pp
    end

    context "Subsetting" do

      it "should do integer subsetting" do
        grades = R.c(1.0, 2.0, 2.0, 3.0, 1.0)

        info = R.data__frame(
          grade: (3..1),
          desc: R.c("Excellent", "Good", "Poor"),
          fail: R.c(false, false, true)
        )

        id = R.match(grades, info.grade)
        table = info[id, :all]

        expect(table.grade[1]).to eq 1
        expect(table.desc.levels[2]).to eq "Good"
        expect(table.fail[4]).to eq false

        info.rownames = info.grade
        table2 = info[grades.as__character, :all]
        
        expect(table2.grade[2]).to eq 2
        expect(table2.desc.levels[1]).to eq "Excellent"
        expect(table2.fail[4]).to eq true

      end

    end

    context "Boostraping" do

      before(:each) do
        @df = R.data__frame(x: R.rep((1..3), each: 2), y: (6..1), z: R.letters[(1..6)])
        R.set__seed(10)
      end

      it "should do reordering with integer subsetting" do
        
        table = @df[R.sample(@df.nrow), :all]
        expect(table.x[3]).to eq 3
        expect(table.y[2]).to eq 5
        expect(table.z.levels[6]).to eq "f"
        
      end

      it "should select random rows with integer subsetting" do
        table = @df[R.sample(@df.nrow, 3), :all]

        expect(table.x[3]).to eq 3
        expect(table.y[1]).to eq 3
        expect(table.z.levels[table.z[2]]).to eq "b"
      end

      it "should randomly reorder a dataframe" do
        df2 = @df[R.sample(@df.nrow), (3..1)]

        expect(df2.z.levels[df2.z[4]]).to eq "c"
        expect(df2.y[2]).to eq 5
        expect(df2.x[5]).to eq 1
      end

      it "should reorder by a given variable" do
        df2 = @df[R.sample(@df.nrow), (3..1)]
        df2 = df2[df2.x.order, :all]

        expect(df2.x[1]).to eq 1
        expect(df2.y[1]).to eq 5
        expect(df2.z.levels[df2.z[1]]).to eq "b"
      end

      it "should reorder variables" do
        df2 = @df[R.sample(@df.nrow), (3..1)]
        df2 = df2[df2.x.order, :all]

        df2 = df2[:all, df2.names.order]

        expect(df2.names.all__equal R.c("x", "y", "z")).to eq true
      end
      
    end    
    
  end
  
end

