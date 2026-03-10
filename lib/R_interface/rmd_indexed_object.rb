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
  # Module to be included for objects that have multi dimensional indices, such as
  # array and dataframe
  #--------------------------------------------------------------------------------------
  
  module MDIndexedObject

    #--------------------------------------------------------------------------------------
    # Index a DataFrame by using []
    #--------------------------------------------------------------------------------------

    def [](*index)
      if (index.size > 1)
        # DataFrame single-cell only when both indices are scalar (one row, one column): use [[ so R returns scalar
        single_cell = index.size == 2 && self.is_a?(::R::DataFrame) &&
          index[0].is_a?(::Integer) && (index[1].is_a?(::Integer) || index[1].is_a?(::String))
        fn = single_cell ? R::Support.dbk_index : R::Support.md_index
        R::Support.exec_function(fn, @r_interop, *index)
      else
        super(*index)
      end
    end

  end

end
