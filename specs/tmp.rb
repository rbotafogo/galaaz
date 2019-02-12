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
# require 'ggplot'
R.library('kableExtra')
R.library('knitr')

script = <<-Rb
  vec = R.c(a: 1, b: 2, c: 3)
  puts vec
  outputs vec.kable
  outputs (~:mtcars).kable
Rb

options = R.list()
options[["code"]] = script
options[["include"]] = true
options[['message']] = true
options[['warning']] = true
options[['eval']] = true

out = GalaazUtil.exec_ruby(options)
puts out
puts RubyChunk.get_outputs

# puts out.class

=begin
vec = R.c(1, 2, 3)
html = vec.kable
puts "++++++"
puts html.knit_print
=end

=begin
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
=end
