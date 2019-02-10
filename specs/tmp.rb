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

# require 'galaaz'
# require 'ggplot'
require 'stringio'

class StringIO
  
  def puts(*args)
    
    if args.empty?
      write(DEFAULT_RECORD_SEPARATOR)
    else
      args.each do |arg|
        if arg.nil?
          line = ''
        elsif Thread.guarding? arg
          line = '[...]'
        else
          begin
            arg = Truffle::Type.coerce_to(arg, Array, :to_ary)
            Thread.recursion_guard arg do
              arg.each { |a| puts a }
            end
            next
          rescue
            line = arg.to_s
          end
        end

        write(line)
        write(DEFAULT_RECORD_SEPARATOR) # unless line[-1] == ?\n
      end
    end

    nil
  end

end

class Test

  def to_s
    puts "hello there second line"
    puts "this is the second line"
  end
  
end

$stdout = StringIO.new

t = Test.new
puts t
out = $stdout.string

$stdout = STDOUT

puts out
