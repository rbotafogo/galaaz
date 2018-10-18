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
    include IndexedObject
    include BinaryOperators
    include ExecBinOp
    include UnaryOperators
    include Enumerable
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def initialize(r_interop)
      super(r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    # When indexing with '[' or '[[' an R object is returned.  Sometimes we need to have
    # access to an umboxed Ruby element, for instance, in an numeric array, we might want
    # to receive the actual number that can be used in a Ruby method.  In this case, we
    # use the '<<' operator.
    # @return the Ruby element at the given index in the vector
    #--------------------------------------------------------------------------------------

    def <<(index)
      @r_interop[index]
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def pop
      self << 0
    end
    
    #--------------------------------------------------------------------------------------
    # @bug
    # Each cannot return a Enumerator because R is single threaded.  When this restriction
    # is removed, make each return self.to_enum
    #--------------------------------------------------------------------------------------

    def each(result = :vec)

      case result
      when :vec
        # length is a R::Vector, in order to extract its size as a Numeric we need to
        # use the << operator
        (1..length << 0).each do |i|
          yield self[i]
        end
      when :native
        (0...length << 0).each do |i|
          yield self << i
        end
      else
        raise "Type #{result} is unknown for method :each"
      end
      
    end

    #--------------------------------------------------------------------------------------
    # Need to override each_with_index, as R indexing starts at 1
    #--------------------------------------------------------------------------------------

    def each_with_index(result = :vec)
      case result
      when :vec
        (1..length << 0).each do |i|
          yield self[i], i
        end
      when :native
        (0...length << 0).each do |i|
          yield self << i, i
        end
      else
        raise "Type #{result} is unknown for method :each"
      end
      
    end
    
    #--------------------------------------------------------------------------------------
    # SHOULD DEFINE COMPARISON BETWEEN TWO VECTORS
    #--------------------------------------------------------------------------------------

    def <=>(other_vector)
      
    end
    
  end
  
end

