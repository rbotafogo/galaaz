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
  
  context "Using environment" do

    before(:all) do
      # create two environments
      @a_env = R.new__env
      @b_env = R.new__env
    end
    
    it "should allow the creation of new environments" do
      expect(@a_env.typeof).to eq R.c("environment")
      expect(@a_env.rclass).to eq R.c("environment")
      expect(@a_env.ls.length).to eq 0
      expect(@b_env.ls.length).to eq 0
    end

    it "should allow accessing key, value pairs to environments, with 'set' and 'get'" do
      @a_env.set(:a, 25)
      expect(@a_env.ls.length).to eq 1
      expect(@a_env.ls).to eq R.c("a")
      
      expect(@b_env.ls.length).to eq 0
      expect(@a_env.get(:a)).to eq 25
      @a_env.set(:b, 33)
      expect(@a_env.ls.length).to eq 2
      expect(@a_env.ls).to eq R.c("a", "b")
      
      expect(@a_env.get(:b)).to eq 33
      expect(@a_env.get(:b)).not_to eq 25
    end

    it "should allow accessing key, value pairs to environments, with '.x' and 'x ='" do
      expect(@a_env.ls.length).to eq 0
      @a_env.a = 30
      expect(@a_env.ls.length).to eq 1
      expect(@a_env.a).to eq R.c("a")

      @b_env.vec = R.c(1, 2, 3, 4)
      expect(@b_env.ls).to eq 1
      expect(@b_env.vec).to eq R.c(1, 2, 3, 4)
    end

    it "should allow accessing key, value pairs to environments, with '[[" do
      expect(@a_env.ls.length).to eq 0
      @a_env.a = "This is a string"
      expect(@a_env[["a"]]).to eq R.c("This is a string")
    end

    it "should call methods on the environment as every other R::Object" do
      # we have already seen that we can apply 'ls' to an environment
      expect(@a_env.ls).to eq 0
      expect(R.ls(@a_env)).to eq 0
    end

    it "allows multiple names to point to the same object" do
      @a_env.a = false
      @a_env.b = "a"
      @a_env.c = 2.3
      @a_env.d = (1..3)
      
      expect(@a_env.b).to eq R.c(1, 2, 3)
      expect(@a_env.d).to eq R.c(1, 2, 3)

      @a_env.a = @a_env.d
      expect(@a_env.a).to eq R.c(1, 2, 3)
    end
    
  end

end

