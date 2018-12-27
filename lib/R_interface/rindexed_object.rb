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

    def [](index)
      if (index.is_a? Array)
      # R::Support.exec_function_name("`[[`", @r_interop, R.internal_eval(:c, *index))
        R::Support.exec_function(R::Support.dbk_index, @r_interop,
                                 R.internal_eval(:c, *index))
      else
        R::Support.exec_function_name("`[`", @r_interop, index)
      end
    end
    
    #--------------------------------------------------------------------------------------
    # subset assign a vector with an index to a value
    # @param index [Array] The vector index
    # @param values [R::Object] The values to assign to the index.  Note that
    # index can span multiple
    # values, for ex., R.c(2, 3, 5)
    #--------------------------------------------------------------------------------------

    def []=(index, values)
      setR_name("`[<-`", index, values)
      self
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def size
      length << 0
    end
    
  end

end
