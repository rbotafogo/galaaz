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

  #----------------------------------------------------------------------------------------
  context "Create DataFrame" do

    it "should create a dataframe from a vector" do
      vec = R.seq(6)
      vec.dim = R.c(2, 3)
      
      # create a DataFrame from a vector
      df = R.as__data__frame(vec)
      expect(df[1, "V1"]).to eq 1
      expect(df[:all, "V1"].identical(R.c(1, 2))).to eq true
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
    
  end

end
