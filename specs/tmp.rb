# coding: utf-8
require '../config'
require 'cantata'

class Callback

  def f(x, y)
    y + x
  end
  
end

=begin
cbk = Callback.new
Polyglot.export("ruby_obj", cbk)

Polyglot.eval("R", <<-R)

  ruby_obj = import("ruby_obj")
  ruby_obj$f(2, 3)

R
=end


#=begin
remote = Polyglot.eval("R", <<-R)
  function(rb_method) {
    print("in remote")
    rb_method(2, 3)
  }
R

#remote.call(Callback.new)
#=end
proc = Proc.new { |x, y| x - y }
remote.call(proc)

proc2 = Proc.new { |x, y| Math.cos(x); x }
remote.call(proc2)

