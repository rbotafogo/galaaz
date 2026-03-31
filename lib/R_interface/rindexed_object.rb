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
      # If we have multiple indices, or a single array index, use [[ or `[` for names
      if (index.size > 1) || (index[0].is_a? Array)
        args = (index.size > 1) ? index : index[0]
        # For DataFrame with two indices: R's [[i,j]] is row i, col j. R's [[ does not accept character indices; use `[` for row/col names.
        # When any index is :all, use `[` (single bracket) so R gets m[i,] or m[,j]; `[[` does not accept missing subscript.
        # When any index is an R object (e.g. vector), use `[`; `[[` only selects one element ("attempt to select more than one element").
        use_md = (args.size == 2 && self.is_a?(::R::DataFrame) && (args[0].is_a?(::String) || args[0].is_a?(::Symbol) || args[1].is_a?(::String) || args[1].is_a?(::Symbol))) ||
                 (args.size == 2 && (args[0] == :all || args[1] == :all)) ||
                 (args.size == 2 && (args[0].is_a?(::R::Object) || args[1].is_a?(::R::Object)))
        if use_md
          ::R::Support.exec_function(::R::Support.md_index, self, *args)
        else
          ::R::Support.exec_function(::R::Support.dbk_index, self, *args)
        end
      else
        if self.is_a?(::R::DataFrame) && index.size == 1 &&
           (index[0].is_a?(::R::Language) || index[0].is_a?(::R::Object))
          # For data.frame, a single logical/language index is expected to filter rows.
          # Evaluate language conditions in data-frame context, then subset df[cond, ].
          row_filter = index[0].is_a?(::R::Language) ? ::R::Support.exec_function("with", self, index[0]) : index[0]
          ::R::Support.exec_function(::R::Support.md_index, self, row_filter, :all)
        else
          ::R::Support.exec_function_name("`[`", self, *index)
        end
      end
    rescue ::RuntimeError => e
      if e.message.to_s.include?("incorrect number of subscripts")
        ::Kernel.raise(::ArgumentError, e.message)
      end
      ::Kernel.raise(e)
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
