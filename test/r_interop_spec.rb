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

describe R do

  R.eval(<<-R)

  get = function(list, index) {
    return (list[[index]]);
    }

  set = function(list, comp, value) {
    list[[comp]] = value;
    print(list);
    return(list);
    }

   create = function(values, n) {
     names(values) = n;
     return(values);
     } 
  R
  
  context "Accessing R through eval" do

    it "shoud create named objects in R" do
      # using Ruby heredoc to write R code
      R.eval(<<-R)
      x <- c(1, 2, 3);
      hyp <- function(x, y) { sqrt(x^2 + y^2) };
      R
    end
    
    it "should use named objects in R" do
      R.eval(<<-R)
      print(x);
      print(hyp(3, 4));
      R
    end

    it "should retrieve and used named R objects in Ruby" do
      # retrieve x and hyp from R and attribute it to local Ruby variables
      x = R.eval("x")
      # hyp is an R function and works like a named function in Ruby
      hyp = R.eval("hyp")

      # is is a foreign object
      expect(Truffle::Interop.foreign?(x)).to be true
      expect(x[0]).to eq 1.0

      # calling a named function or block is done by use of the 'call' method
      expect(hyp.call(3, 4)).to eq 5.0

    end
  end
  
  context "When passing primitive values" do

    it "should work with numbers" do
      var = R.eval("4")
      expect(4.0).to eq var
      expect(var.class).to eq Float
    end

    # This has a bug that will be fixed by next version of Truffle
    it "should work with characters" do
      # var = R.eval("'Hello'")
      # p var[0]
      # expect("'Hello World'").to eq var
    end

    it "should work with c string" do
      var1 = R.c("Hello")
      p "var1 is a vector: #{var1} of size #{var1.size}"
      p var1[0]
      var2 = R.c("Hello", "beautiful", "world!")
      p "var2 is a vector: #{var2} of size #{var2.size}"
      p var2
      p var2[0]
      # var2 = var2.delete(1)
      # p var2[0]
      del = R.c(0, 1)
      # this does not work! Need to check how to call methods on an external
      # vector
      # p del
      # var2[del]
    end

    # All the method calls here will be called through the R scope, i.e., they
    # will be called with R.<function>(parameters).  This is different from
    # getting the function definition in Ruby by calling R.eval(<function name>)
    # and then calling <function name>.call(parameters).  This second case will be
    # dealt in another context.
    context "When passing parameters to R functions in the R scope" do

      it "should be able to pass Numbers" do
        # note that method hyp was defined in another block, but it persists accross
        # calls to the R scope.
        expect(R.hyp(3, 4)).to eq 5.0
      end

#=begin      
      it "should be able to pass Strings" do
        p "passing params"
        vec = R.c("Hello", "world!")
        params = R.create(R.list("--- "), R.c("collapse"))
        str = R.paste0(vec, params)
        # str = R.paste(vec, sep:  " ")
        p str.to_s
        R.str(str)
        p "done"
      end
#=end      
    end

  end
  
  context "When working with foreign methods" do

    # create an R vector. R methods are access through the R namespace
    # R.c creates an R vector.
    before(:context) do
      @val = R.c(1, 2, 3, 4)
    end

    # The returned value from calling method 'c' in a foreign value in Ruby
    it "should create a foreign R object" do
      expect(Truffle::Interop.foreign?(@val)).to be true
    end

    # Check that we can access the elements of the foreign vector.  Note that
    # indexing starts at 0 and not at 1.
    it "should access data indexing from 0" do
      expect(1.0).to eq @val[0]
      expect(2.0).not_to eql @val[0]
      expect(4.0).to eq @val[3]
    end

    context "When working with lists" do

      p "starting working with list"
      
      list = R.list("hello", "there", "... ")
      R.str(list)      
      p list.to_s
      p list[0]
      print "\n\n"
      p R.get(list, 3)
      list = R.set(list, "added", "!!")
      p list.to_s
      p list["added"]
      nl = R.create(R.list("hello", "there"), R.c("n1", "n2"))
      R.str(nl)
      # R.setnames(list, 0, "hi")
      # p R.names(list) = R.c("a", "b", "c")
      # p R.names(list)
      
      p "end working with lists"
      print "\n\n"
    end
    
    
  end
end
