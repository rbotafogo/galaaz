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

module R

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------
  
  module IndexedObject
    
    #--------------------------------------------------------------------------------------
    # subset a vector with an index
    # @index The vector index.
    #--------------------------------------------------------------------------------------

    def[](index)
      if (index.is_a? Array)
        R::Support.exec_function_name("`[[`", @r_interop, R.internal_eval(:c, *index))
      else
        R::Support.exec_function_name("`[`", @r_interop, index)
      end
    end
    
    #--------------------------------------------------------------------------------------
    # subset assign a vector with an index to a value
    # @index The vector index
    # @values The values to assign to the index.  Note that index can span multiple
    # values, for ex., R.c(2, 3, 5)
    #--------------------------------------------------------------------------------------

=begin    
    def[]=(index, values)
      r_values = R.parse(values)
      dbk, r_index = parse_index(index)
      dbk ?
        R::Object.build(R.dbk_assign.call(@r_interop, *r_index, *r_values)) :
        R::Object.build(R.subset_assign.call(@r_interop, *r_index, *r_values))
    end
=end
    
    def[]=(index, values)
      setR_name("`[<-`", index, values)
      self
      # r_values = R.parse(values)
      # r_index = R.parse(index)
      # l = R::Support.parse2list(@r_interop, index, values)
      # R::Object.build(R::Support.eval("`[<-`").call(@r_interop, *r_index, *r_values))
      
      #p "assigning"
      #p index
      #p values
      #R::Support.exec_function_name("`[<-`", @r_interop, index, values)
    end

  end

  #--------------------------------------------------------------------------------------
  # Note that binary operators work on vectors and matrices as well as scalars. 
  #--------------------------------------------------------------------------------------
  
  module BinaryOperators
    
    #--------------------------------------------------------------------------------------
    # @param other_object
    #--------------------------------------------------------------------------------------

    def +(other_object)
      R::Support.exec_function_name("`+`", @r_interop, other_object.r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def -(other_object)
      R::Support.exec_function_name("`-`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def *(other_object)
      R::Support.exec_function_name("`*`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def /(other_object)
      R::Support.exec_function_name("`/`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def **(other_object)
      R::Support.exec_function_name("`**`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def %(other_object)
      R::Support.exec_function_name("`%%`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def ==(other_object)
      R::Support.exec_function_name("`==`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def <(other_object)
      R::Support.exec_function_name("`<`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def <=(other_object)
      R::Support.exec_function_name("`<=`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def >(other_object)
      R::Support.exec_function_name("`>`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def >=(other_object)
      R::Support.exec_function_name("`>=`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def !=(other_object)
      R::Support.exec_function_name("`!=`", @r_interop, other_object.r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def and(other_object)
      R::Support.exec_function_name("`&`", @r_interop, other_object.r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def or(other_object)
      R::Support.exec_function_name("`|`", @r_interop, other_object.r_interop)
    end

  end
  
  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  module UnaryOperators

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def !
      R::Support.exec_function_name("`!`", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def -@
      R::Support.exec_function_name("`-`", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def +@
      R::Support.exec_function_name("`+`", @r_interop)
    end

  end

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  class Vector < Object
    include IndexedObject
    include BinaryOperators
    include UnaryOperators
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def initialize(r_interop)
      super(r_interop)
    end
    
  end
  
  
  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  class List < Object
    include IndexedObject
  end

end

require_relative 'rdata_frame'
