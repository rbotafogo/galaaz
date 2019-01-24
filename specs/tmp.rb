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

# naturgy soluções

require 'galaaz'
# require 'ggplot'

x = R.seq(1, 10)
puts x[5] << 0

# expect(x[5] == 5).to eq true
y = R.seq(-~:pi, ~:pi, length: 50)
puts y[1] << 0
puts y[7] << 0
puts y[26] << 0

#expect(y[1].all__equal(-3.14159265)).to eq true
#expect(y[7].all__equal(-2.37222302)).to eq true
#expect(y[26].all__equal(0.06411414)).to eq true


R.set__seed(3)
x = R.rnorm(50)
y = x + R.rnorm(50, mean: 40, sd: 0.1)

puts R.cor(x, y) << 0




=begin
formula = :cyl.til :exp
puts formula
puts formula.to_s

formula = E.log(:y).til :a + E.log(:x)
puts formula
puts formula.to_s


lm_fit5 = R.lm((:medv.til E.poly(:lstat, 5.0)), data: :Boston)
puts lm_fit5.summary

=end
