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

require 'stringio'

#----------------------------------------------------------------------------------------
# Class RubyChunk is used only as a context for all ruby chunks in the rmarkdown file.
# This allows for chunks to access instance_variables (@)
#----------------------------------------------------------------------------------------

class RubyChunk

end

#----------------------------------------------------------------------------------------
#
#----------------------------------------------------------------------------------------

module GalaazUtil

  #----------------------------------------------------------------------------------------
  # Executes the ruby code with the given options.
  # @param options [R::List] An R list of options
  # @return [R::List] an R list with everything that needs to be outputed.
  # The options are:
  # * options.code: the ruby code
  # * options[["eval"]]: evaluate if true
  # * options.echo: if true, show the source code of the chunk in the output
  # * options.message: if true, show error message if any exception in the ruby code
  # * options.warning: if true, show stack trace from the ruby code
  # * options.include: if true, include the code output
  # Note that we need to access the 'eval' element of the list by indexing as
  # options[["eval"]], this is because eval is a Ruby function and doing options.eval
  # will call the eval method on options, which is not what we want
  #----------------------------------------------------------------------------------------

  # def self.exec_ruby(code, eval, echo, message, warning, include)
  def self.exec_ruby(options)

    # read the chunk code
    code = R.paste(options.code, collapse: "\n") << 0

    # the output should be a list with the proper structure to pass to
    # function engine_output.
    out_list = R.list(R.structure(R.list(src: code), class: 'source'))
    
    begin
      # Set up standard output as a StringIO object.
      # $stdout = StringIO.new
      $stdout = STDOUT
      RubyChunk.instance_eval(code) if (options[["eval"]] << 0)
      out = $stdout.string
      # add the result from ruby execution to the out_list
      out_list = R.c(out_list, out)
    rescue StandardError => e
      if (options.message << 0)
        message = R.list(R.structure(R.list(message: e.message), class: 'message'))
        out_list = R.c(out_list, message)
      end
      if (options.warning << 0)
        warning = R.list(R.structure(R.list(message: e.backtrace.inspect), class: 'message'))
        out_list = R.c(out_list, warning)
      end
    ensure
      # return $stdout to standard output
      $stdout = STDOUT
    end

    # TODO: check the name of procedures since communication is
    # bidirectional.  The name parse_arg was done thinking only on
    # the Ruby -> R direction.
    # exec_ruby returns its output to an R script, so we need to pass
    # the output (out_list) through parse_arg to make it available
    # to R.
    (options.include << 0)? R::Support.parse_arg(out_list) : nil

  end

end
