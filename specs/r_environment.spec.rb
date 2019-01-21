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

require 'galaaz'

describe R::Environment do
  
  #----------------------------------------------------------------------------------------
  context "Using environment" do

    before(:each) do
      # create two environments
      @a_env = R.env
      @b_env = R.env
    end
    
    it "should allow the creation of new environments" do
      expect(@a_env.typeof).to eq R.c("environment")
      expect(@a_env.rclass).to eq R.c("environment")
      expect(@a_env.env_names.length).to eq 0
      expect(@b_env.env_names.length).to eq 0
    end

    it "should allow accessing key, value pairs to environments, with 'set' and 'get'" do
      @a_env.set(:a, 25)
      expect(@a_env.env_names.length).to eq 1
      expect(@a_env.env_names).to eq R.c("a")
      
      expect(@b_env.env_names.length).to eq 0
      expect(@a_env.get(:a)).to eq 25
      @a_env.set(:b, 33)
      expect(@a_env.env_names.length).to eq 2
      expect(@a_env.env_names).to eq R.c("a", "b")
      
      expect(@a_env.get(:b)).to eq 33
      expect(@a_env.get(:b)).not_to eq 25
    end

    it "should allow accessing key, value pairs to environments, with '.x' and 'x ='" do
      expect(@a_env.env_names.length).to eq 0
      @a_env.a = 30
      expect(@a_env.env_names.length).to eq 1
      expect(@a_env.a).to eq 30

      @b_env.vec = R.c(1, 2, 3, 4)
      expect(@b_env.env_names).to eq "vec"
      expect(@b_env.env_names.length).to eq 1
      expect(@b_env.vec).to eq R.c(1, 2, 3, 4)
    end

    it "should allow accessing key, value pairs to environments, with '[[" do
      expect(@a_env.env_names.length).to eq 0
      @a_env.a = "This is a string"
      expect(@a_env[["a"]]).to eq R.c("This is a string")
    end

    it "should call methods on the environment as every other R::Object" do
      # we have already seen that we can apply 'ls' to an environment
      expect(@a_env.env_names.length).to eq 0
      expect(R.env_names(@a_env).length).to eq 0
    end

    it "allows multiple names to point to the same object" do
      @a_env.a = false
      @a_env.b = "a"
      @a_env.c = (2..3)
      @a_env.d = (1..3)
      
      expect(@a_env.b).to eq "a"
      expect(@a_env.d).to eq R.c(1, 2, 3)

      @a_env.a = @a_env.d
      expect(@a_env.a).to eq R.c(1, 2, 3)
    end

    it "should allow removing elements from an environment" do
      @a_env.a = false
      @a_env.b = "a"
      @a_env.c = (2..3)
      @a_env.d = (1..3)

      expect(@a_env.a).to eq false
      expect(@a_env.b).to eq "a"
      R.rm("a", envir: @a_env)
      expect { @a_env.a }.to raise_error(NoMethodError)
    end

    it "should not be able to subset the environment with '['" do
      @a_env.a = false
      expect { @a_env['a'] }.to raise_error(RuntimeError)
    end
    
  end

  #----------------------------------------------------------------------------------------
  context "Evaluating expressions" do

    before(:each) do
      R.len = 10
      R.sd = 20
      vec = R.c(1, 2, 3, 4)
      R.x = R.c(1, 2, 3, 4)
    end

    it "should evaluate an expression in the context of a data maks" do
      myenv = R.env
      myenv.e1 = R.expr(:len)
      myenv.e2 = R.expr(:sd)
      myenv.e3 = R.expr(R.c(1, 2, 3, 4))
      
      e4 = R.expr(:e1 + :e2 + :e3)
      expect(e4.to_s).to eq "e1 + e2 + e3"
      expect(e4.eval(myenv.new_data_mask)).to eq R.c(31, 32, 33, 34)

    end
    
  end
    
end

