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

#==========================================================================================
#
#==========================================================================================

class Range

  #----------------------------------------------------------------------------------------
  # Defines unary minus operation for ranges
  #----------------------------------------------------------------------------------------
  
  def -@
    NegRange.new(self.begin, self.end)
  end

end

#==========================================================================================
# Class NegRange exists to represent a negative range, e.g., -(1...10).  Such a range is
# used to index vectors and means all elements but the ones in the given range.  Class
# NegRange is parsed to become "-(1:10)" in R.
#==========================================================================================

class NegRange < Range

end


module R

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.eval(string)
    Polyglot.eval("R", string)
  end

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.method_missing(symbol, *args)

    name = symbol.to_s
    # convert '__' to '.'
    name.gsub!(/__/,".")
    # Method 'rclass' is a substitute for R method 'class'.  Needed, as 'class' is also
    # a Ruby method on an object
    name.gsub!("rclass", "class")

    # params = parse(*args)
    eval(name).call(*args)
    
  end  

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.parse(*args)

    params = Array.new

    args.each do |arg|
      if(Truffle::Interop.foreign?(arg) == true)
        p "I'm a pointer to an interop"
        # just add the Interop parameter to the parameter list
        params << arg
      else
        if (arg.is_a? Numeric)
          params << arg
        elsif(arg.is_a? String)
          params << "\"#{arg}\""
        elsif (arg.is_a? Symbol)
          var = eval("#{arg.to_s}")
          params << var.r
        elsif (arg.is_a? TrueClass)
          params << "TRUE"
        elsif (arg.is_a? FalseClass)
          params << "FALSE"
        elsif (arg == nil)
          params << "NULL"
        elsif (arg.is_a? NegRange)
          final_value = (arg.exclude_end?)? (arg.end - 1) : arg.end
          params << "-(#{arg.begin}:#{final_value})"
        elsif (arg.is_a? Range)
          final_value = (arg.exclude_end?)? (arg.end - 1) : arg.end
          params << "(#{arg.begin}:#{final_value})"
        elsif (arg.is_a? Hash)
          arg.each_pair do |key, value|
            # k = key.to_s.gsub(/__/,".")
            params << "#{key.to_s.gsub(/__/,'.')} = #{parse(value)}"
            # params << "#{k} = #{parse(value)}"
          end
        elsif ((arg.is_a? Renjin::RubySexp) || (arg.is_a? Array) || (arg.is_a? MDArray))
          params << arg.r
        # elsif 
        #  params << arg.inspect
        else
          raise "Unknown parameter type for R: #{arg}"
        end
      end
    end
    
    # params.join(",")
    params
      
  end
  
end

