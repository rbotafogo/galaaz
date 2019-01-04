# coding: utf-8

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

describe R::Vector do
  
  context "When creating vectors" do

    it "should allow changing an element of a vector attribute" do
      # pending "Need to implement new function for this"
      # set names
      @vect = R.c(1, 2, 3, 4, 5, 6)
      @vect.names = R.c("a", "b", "c", "d", "e", "f")
      
      @vect.names[2] = "hello"
      puts @vect.names
      puts @vect.names[2]
      
      # expect(@vect.names[2]).to eq R.c("hello")
    end
    
  end
end

=begin
a_env = R.new__env
puts a_env               # <environment: xxxx>
puts a_env.typeof
puts a_env.rclass

puts a_env.parent__env   # <environment: yyyy>
puts a_env.ls            # character(0)

a_env.set(:a, 25)
a_env.set(:b, 30)

puts a_env.ls             # [1] "a" "b"
puts a_env.get("a")       # [1] 25
puts a_env.get("b")       # [1] 30
puts a_env.a              # [1] 25
puts a_env[["a"]]         # [1] 25
puts a_env.c              # calls method 'c' on a_env

# puts a_env["a"]         # RuntimeError: Not subsettable
a_env.c = 40              # set the 'c' key to 40 
puts a_env.c              # No more a call to method 'c': [1] 40
a_env.d = R.c(1, 2, 3, 4)
puts a_env.d

# puts a_env.d              # RuntimeError: Error: object 'd' not found
=end
