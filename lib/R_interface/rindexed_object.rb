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
    # @param index [Array] The vector index.
    #--------------------------------------------------------------------------------------

    def [](*index)
      # dealing with double indexing function '[['
      # If we have multiple indices, or a single array index, use [[
      if (index.size > 1) || (index[0].is_a? Array)
        ::R::Support.exec_function(::R::Support.dbk_index, @r_interop, *index)
      else
        ::R::Support.exec_function_name("`[`", @r_interop, *index)
      end
    end
    
    #--------------------------------------------------------------------------------------
    # subset assign a vector with an index to a value
    # @param index [Array] The vector index
    # @param values [R::Object] The values to assign to the index.  Note that
    # index can span multiple
    # values, for ex., R.c(2, 3, 5)
    #--------------------------------------------------------------------------------------

    def []=(*args)
      values = args.pop
      index = args

      # Assign result back to same handle so the object is updated in place (R's x[i] <- v semantics)
      if (index.size > 1) || (index[0].is_a? Array)
        all_args = [@r_interop, *index, values].map { |a| ::R::Support.parse_arg(a) }.join(", ")
        ::R.bridge.eval_r("#{@r_interop} <- `[[<-`(#{all_args})")
      else
        idx_r = ::R::Support.parse_arg(index[0])
        vals_r = ::R::Support.parse_arg(values)
        ::R.bridge.eval_r("#{@r_interop} <- `[<-`(#{@r_interop}, #{idx_r}, #{vals_r})")
      end

      self
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def size
      length.unboxed_get(0)
    end
    
  end

end
