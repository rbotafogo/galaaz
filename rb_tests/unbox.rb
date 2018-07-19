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

# set the test option
#
# when option == 1, method exec_funtion in the R module is executed.  It calls
# @@exec_from_ruby, an R method defined in the R module to execute the call.
# The returned value is NOT unboxed at the end
#
# when option == 2, method exec_function in the R module is executed. It calls
# exec_from_ruby, an R method defined in the global Ruby scope.  The returned
# value is NOT unboxed at the end
#
# when option == 3, method exec_from_ruby is called from the global scope, it
# does not go through method exec_function. In this case the returned value
# IS unboxed at the end

$option = 3

$exec_from_ruby = Polyglot.eval("R", <<-R)
  function(...) {
    res = do.call(...)
    print(res);
    res
  }
R

module R

  @@exec_from_ruby = Polyglot.eval("R", <<-R)
    function(...) {
      res = do.call(...);
      print(res);
      res
    }
    R

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------
  
  def self.eval(string)
    Polyglot.eval("R", string)
  end
  
  #----------------------------------------------------------------------------------------
  # Parse all arguments into an R list of arguments
  #----------------------------------------------------------------------------------------
  
  def self.parse2list(*args)
    params = Polyglot.eval("R", "list()")
    args.each_with_index do |arg, i|
      params = R.eval("`[[<-`").call(params, i+1, arg)
    end
    params
  end
  
  #----------------------------------------------------------------------------------------
  # @param function [R function (Interop)] R function to execute
  # @args [Argument list] arguments for the function
  #----------------------------------------------------------------------------------------

  def self.prep(function, *args)
    pl = R.parse2list(*args)
    p "Executing #{function.to_s} with arguments #{pl.to_s}"
    pl
  end
  
  def self.exec_function(function, *args)
    pl = prep(function, *args)
    if ($option == 1 || $option == 3)
      @@exec_from_ruby.call(function, pl)
    else
      $exec_from_ruby.call(function,pl)
    end
  end
  
end

func = Polyglot.eval("R", "c")
vect = R.exec_function(func, 1, 2, 3, 4, 5)

func = Polyglot.eval("R", "`[`")
v1 = R.exec_function(func, vect, -2)

if ($option == 1 || $option == 2)
  v2 = R.exec_function(func, v1, 2)
elsif ($option == 3)
  pl = R.prep(func, v1, 2)
  v2 = $exec_from_ruby.call(func, pl)
end

p v2.to_s


=begin
vect = R.c(1, 2, 3, 4, 5, 6)
vect.names = R.c("a", "b", "c", "d", "e", "f")
# vect.names[2] = "hello"
vect.names(2, "hello")
vect.names.pp

#expect(vect.names[2]).to eq "hello"
=end


=begin
p "Doing Polyglot"

module Test

  def self.doing
    pl = Polyglot.eval("R", "list").call(1.0, 2, 3, 4, 5)
    func = Polyglot.eval("R", "c")
    # p func.to_s
    # R.print.call(pl)
    vect = Polyglot.eval("R", "do.call").call(func, pl)
    # p Polyglot.eval("R", "typeof").call(vect).to_s
    # p vect.to_s
    
    func = Polyglot.eval("R", "`[`")
    # p func.to_s
    pl = Polyglot.eval("R", "list").call(vect, -2) 
    # R.print.call(pl)
    v1 = Polyglot.eval("R", "do.call").call(func, pl)
    # p v1.to_s
    
    func = Polyglot.eval("R", "`[`")
    # p func.to_s
    pl = Polyglot.eval("R", "list").call(v1, 2) 
    # R.print.call(pl)
    v2 = Polyglot.eval("R", "do.call").call(func, pl)
    v2
  end
  
end

p Test.doing.to_s

=end



=begin
describe R do

  #----------------------------------------------------------------------------------------
  context "When passing primitive values" do

    it "should subset vector with integer or negative integer" do
      vect = R.c(1, 2, 3, 4, 5)
      expect(vect[5]).to eq 5
      expect(vect[-2][2]).to eq 3
    end
    
  end

end
=end

=begin
df = R.data__frame(x: R.rep((1..3), each: 2),
                   y: (6..1), z: R.letters[(1..6)])

df.pp

# Set seed for reproducibility
R.set__seed(10)

# p R.nrow(df)

p df.nrow
=end


=begin

# Randomly reorder
# df[sample(nrow(df)), ]
df[R.sample(df.nrow), :all]

=end
