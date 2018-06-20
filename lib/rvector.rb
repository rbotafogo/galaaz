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

    # define a function to access the subset '[' method
    @@subset = Polyglot.eval("R", <<-R)
      function(object, index) {
        return(object[index])
        }
    R
    @@subsetAssign = Polyglot.eval("R", "`[<-`")
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def initialize(r_interop)
      super(r_interop)
    end

    #--------------------------------------------------------------------------------------
    # subset a vector with an index
    # @index The vector index.
    #--------------------------------------------------------------------------------------

    def[](index)
      params = R.parse(index)
      R::Object.build(@@subset.call(@r_interop, *params))
    end
    
    #--------------------------------------------------------------------------------------
    # subset assign a vector with an index to a value
    # @index The vector index
    # @values The values to assign to the index.  Note that index can span multiple
    # values, for ex., R.c(2, 3, 5)
    #--------------------------------------------------------------------------------------

    def[]=(index, values)
      r_index = R.parse(index)
      r_values = R.parse(values)
      R::Object.build(@@subsetAssign.call(@r_interop, *r_index, *r_values))
    end
    
  end
  

end
