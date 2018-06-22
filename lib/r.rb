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

require_relative 'robject'
require_relative 'ruby_extensions'

module R

  @@make_params = Polyglot.eval("R", <<-R)
    function(list, list_names) {
      names(list) = list_names
    }
  R
  
  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.eval(string)
    Polyglot.eval("R", string)
  end

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def internal_eval(symbol, *args)
    name = symbol.to_s
    # convert '__' to '.'
    name.gsub!(/__/,".")
    # Method 'rclass' is a substitute for R method 'class'.  Needed, as 'class' is also
    # a Ruby method on an object
    name.gsub!("rclass", "class")

    params = R.parse(*args)
    eval(name).call(*args)
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

    # params, keys, values = R.parse(*args)
    params = R.parse(*args)

=begin   
    if (keys.size > 0)
      list_names = Array.new(params.size) {""}
      parameters = params.concat(values)
      list_names.concat(keys)
      params_list = R.eval("list").call(*parameters)
      @@make_params.call(params_list, list_names)
      return R::Object.build(eval("do.call").call(name, params_list))
    end
=end

    # build an RObject from the returned value
    R::Object.build(eval(name).call(*params))
    
  end  
  
  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.parse(*args)
    
    params = Array.new
    keys = []
    values = []
    
    args.each do |arg|
      if (Truffle::Interop.foreign?(arg) == true)
        params << arg
      elsif (arg.is_a? R::Object)
        params << arg.r_interop
=begin
      # Needs to consider what should be done with a Ruby Array sent to R as
      # a parameter.  Should it be converted to an R vector or be a foreign
      # pointer?        
      elsif (arg.is_a? Array)
        if (arg.size == 1)
          params << arg[0]
        else
          # convert the Ruby array to an R vector.  Does not work recursively
          # i.e., [1, 2, 3, [4, 5, 6]] will only convert the first level
          # array and [4, 5, 6] will be a foreign pointer in R.  Should be
          # fixed in future version.
          params << R.c(*arg).r_interop
        end
=end
#=begin        
      elsif (arg.is_a? Hash)
        arg.each_pair do |key, value|
          keys << key.to_s.gsub(/__/,".")
          pa = parse(value)[0]
          values << pa
        end
#=end
      else
        params << arg
      end
    end
    
    # return [params, keys, values.flatten]
    return params

  end
  
  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.interop(object)
    Truffle::Interop.foreign?(object)
  end
  

  private

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.parse2list(*args)

    subsetAssign = Polyglot.eval("R", "`[<-`")
    
    params = Polyglot.eval("R", "return(list())")
    args.each_with_index do |arg, i|
      if (Truffle::Interop.foreign?(arg) == true)
        p "foreign #{i}"
        subsetAssign.call(params, i, arg)
      elsif (arg.is_a? R::Object)
        p "object #{i}"
        subsetAssign.call(params, i, arg.r_interop)
      else
        p "other #{i}"
        subsetAssign.call(params, i, arg)
      end
    end

    # Polyglot.eval("R", "print.default").call(params)
    
  end
  
end

