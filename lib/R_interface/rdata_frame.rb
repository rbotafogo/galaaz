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

  class DataFrame < List
    include MDIndexedObject
    include Enumerable

    #--------------------------------------------------------------------------------------
    # Calls the R.qplot adding the data: parameter
    #--------------------------------------------------------------------------------------

    def qplot(*args)
      print R.qplot(*args, data: self)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def method_missing_assign(column_name, arg)
      setR_name("`[<-`", R.empty_symbol, column_name, arg)
    end

    #--------------------------------------------------------------------------------------
    # Goes through each row of the dataframe and return the whole row as the first element
    # and the row name (Ruby string) as the second
    #--------------------------------------------------------------------------------------

    def each_row

      # nrow is the R function that return the number of rows in the dataset.  This
      # function returns a R::Vector, so we need to extract its first element (<< 0)
      (1..nrow << 0).each do |i|
        yield self[i, :all], self.rownames[i] << 0
      end

    end

    #--------------------------------------------------------------------------------------
    # Goes through each column of the dataframe and return the whole column as the first
    # element and the column name (Ruby string) as the second
    #--------------------------------------------------------------------------------------

    def each_column
      
      # ncol is the R function that return the number of columns in the dataset.  This
      # function returns a R::Vector, so we need to extract its first element (<< 0)
      (1..ncol << 0).each do |i|
        yield self[:all, i], self.names[i] << 0
      end
      
    end

#=begin    
    #--------------------------------------------------------------------------------------
    # @TODO Need to understand why to_ary is being called here and what the effect is of
    # returning the empty array.  For now, doing this returns better error messages in
    # rspec
    #--------------------------------------------------------------------------------------

    def to_ary
      []
    end
#=end

  end
  
end
