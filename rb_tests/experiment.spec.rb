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

  context "When doing experiment... " do

    it "callback a ruby proc" do
      
      def self.r2ruby(*args)
        # p "in r2ruby #{args}"
        args.map { |arg| R::Object.build(arg) }
      end

      rrb = method(:r2ruby)

      # create a callback function that calls the ruby proc
      make_callback = R.eval(<<-R)
        function (r2ruby, proc, ...) {
          function(...) {
            print("doing callback");
            proc(r2ruby(...))
          }
        }
      R

      R.eval(<<-R)
        eval_cost = function(cost, ...) {
          cost(...)
        }
      R
      
      # proc = Proc.new { |x| puts x }
      # rb_callback = make_callback.call(rrb, proc)
      # rb_callback.call(10)

#=begin
      R.eval(<<-R)
        callback2 = function(rb_callback, ...) {
          rb_callback(c(10, 20))
        }
      R

=begin      
      # Rosenbrock Banana function as a cost function
      # (as in the R man page for optim())
      def cost_f(x)
        p "in cost function #{x}"
        x1, x2 = x
        return 100 * (x2 - x1 * x1)**2 + (1 - x1)**2
      end

      proc = method(:cost_f)
      rb_callback = make_callback.call(rrb, proc)
      
      # p R.eval_cost(rb_callback, 10, 20)
      # R.callback2(proc)

      vec = R.c(-1.2, 1)
      # this needs to be fixed... want to return the function
      # optim = R.optim
      optim = R.eval("optim")
      p optim.to_s
      
      opt = R.optim(vec, rb_callback)
      p opt.to_s
      opt.pp
      
=end
=begin
      R.eval(<<-R)
        library(ggplot2)
        ggplot(data = cars, aes(x = dist, y = speed)) + geom_point() 
      R
=end
      
      # l = R.list(R.mtcars)
      # l.pp

      mtcars = R.mtcars
      mtcars.wt
     
      #R.plot(R.mtcars.wt, R.mtcars.mpg, main: "Scatterplot Example",
      #       xlab: "Car Weight ", ylab: "Miles Per Gallon ", pch: 19)
      
      # plot = R.ggplot(data: mtcars)
      # p plot
      # cars = R.eval("cars")
      # p R.cars.to_s
      # p R.callback2
      
      # p cars.to_s
      
    end
    
  end
  
end
