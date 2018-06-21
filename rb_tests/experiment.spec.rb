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

  context "When assigning attributes to a vector" do

    it "should assign names to vectors" do
      vect = R.c(1, 2, 3, 4, 5, 6)
      # R.names(vect) = R.c("a", "b", "c", "d", "e")
      vect.names = R.c("a", "b", "c", "d", "e")
      vect.dim = R.c(3, 2)
      vect.row__names = R.c("A", "B", "C")
      vect.class = "myClass"
      vect.pp
      vect.attributes.pp
      # vect[:names] = R.c("a", "b", "c", "d", "e")
    end

    it "sould create a named list" do

      named_list = R::List.create_named_list(a: "a", b: "b", c: "c", d: "d", e: "e")
=begin      
      l = R.list("a", "b", "c")
      p "constructed named list"
      l.names = R.c("", "", "c")
      l.pp

      p "r named list"
      R.eval(<<-R)
        l = list("a", "b", c = "c");
        print(l);
      R
=end      
    end
    
  end

end
