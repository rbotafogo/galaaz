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
R.require 'stats'

# require 'ggplot'

# Need to fix function 'str'... not printing anything
# anymore
# puts R.str(mtcars)
# shouls allow mtcars[['car name']] = mtcars.rownames

# (~:mtcars).str

describe R::List do
  
  context "The apply family of functions with lists" do


    x = R.list(a: (1..10), beta: R.exp(-3..3), logic: R.c(true, false, false, true))
#puts x

    quant = R.lapply(x, ~:quantile)
#puts quant
#puts quant.a[['50,00000%']]

# puts quant.beta['100%']

    it "ss" do
      
      ret = R.all__equal(quant.beta["100%"],
                         R.c('100%': 20.08553692),
                         tolerance: (~:".Machine").double__eps ** 0.5)
      expect(R.c(1, 2, 3)).to eq false
      # expect(5 == 10).to eq true
    end
  end
end

=begin
# Make @q the function R quantile

#puts quant.a

# puts quant.a[["50%"]]
=end


=begin
R::Support.eval(<<R)
  x = list(a = (1:10), beta = exp(-3:3), logic = c(TRUE, FALSE, FALSE, TRUE))
  quant = lapply(x, quantile)
  print(quant)
R
=end
