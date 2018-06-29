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

  class Vector < Object

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def initialize(r_interop)
      super(r_interop)
    end

    #--------------------------------------------------------------------------------------
    # @bug Need to fix this... Should work for both notations with dbk and single
    # l[R.c(4, 1)].pp
    # expect(l[[4, 1]]).to eq 4
    #--------------------------------------------------------------------------------------

    def parse_index(index)

      if (index.is_a? Array)
        if (index.size == 1)
          [true, index[0]]
        else
          # convert the Ruby array to an R vector.  Does not work recursively
          # i.e., [1, 2, 3, [4, 5, 6]] will only convert the first level
          # array and [4, 5, 6] will be a foreign pointer in R.  At any rate
          # this is not supported in R either.
          [true, R.internal_eval(:c, *index)]
        end
      else
        [false, R.parse(index)]
      end
      
    end
      
    #--------------------------------------------------------------------------------------
    # subset a vector with an index
    # @index The vector index.
    #--------------------------------------------------------------------------------------

    def[](index)
      dbk, r_index = parse_index(index)
      dbk ?
        R::Object.build(@@double_subset.call(@r_interop, r_index)) :
        R::Object.build(@@subset.call(@r_interop, *r_index))
    end
    
    #--------------------------------------------------------------------------------------
    # subset assign a vector with an index to a value
    # @index The vector index
    # @values The values to assign to the index.  Note that index can span multiple
    # values, for ex., R.c(2, 3, 5)
    #--------------------------------------------------------------------------------------

    def[]=(index, values)

      r_values = R.parse(values)
      dbk, r_index = parse_index(index)
=begin
      p
      p "params to []="
      p r_values.to_s
      p dbk
      p r_index
      val = @@subset_assign.call(@r_interop, *r_index, *r_values)
      p val.to_s
      p
=end      
      dbk ?
        R::Object.build(@@dbk_assign.call(@r_interop, *r_index, *r_values)) :
        R::Object.build(@@subset_assign.call(@r_interop, *r_index, *r_values))
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def to_s
      # R.capture__output(@r_interop)
      @r_interop.to_s
    end
                       
  end
  
  
  
  class List < Vector
    
  end


  class DataFrame < List

  end
  
end
