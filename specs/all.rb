# -*- coding: utf-8 -*-

##########################################################################################
# @author Rodrigo Botafogo
#
# Copyright © 2013 Rodrigo Botafogo. All Rights Reserved. Permission to use, copy, modify, 
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

require_relative 'r_eval.spec'

# Specification for Functions
require_relative 'r_function.spec'

# Specification for Ruby expressions
require_relative 'ruby_expression.spec'

# Specification for R::Environment
require_relative 'r_environment.spec'

# Specification for R::Vector
require_relative 'r_vector_creation.spec'
require_relative 'r_vector_object.spec'
require_relative 'r_vector_subsetting.spec'
require_relative 'r_vector_functions.spec'
require_relative 'r_vector_operators.spec'

# Specification for R::Lists
require_relative 'r_list.spec'
require_relative 'r_list_apply.spec'

# Specification for R::Matrix
require_relative 'r_matrix.spec'

# Specification for R::Dataframes
require_relative 'r_dataframe.spec'

#require_relative 'r_formula.spec'

# Testes for NSE
# require_relative 'r_nse.spec'
