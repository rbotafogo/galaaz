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

module GalaazUtil

  #========================================================================================
  # Opens the given filename for reading and returns the file content so that it can be
  # printed as a code chunk in rmarkdown
  # @param filename [String] the name of the file to be found.  If the file has no
  #    extension then '.rb' is assumed
  # @param relative [String] containing either 'require_relative ' or 'require '.  In the
  #    first case looks on the current directory, on the latter, searches the $LOAD_PATH
  # @param pwd [String] Directory to look at when 'require_relative ', by default, its
  #    the pwd directory
  #========================================================================================
  
  def self.inline_file(filename, relative, pwd = Dir.pwd)

    filename << ".rb" if File.extname(filename) == ""
    file = "#{pwd}/#{filename}"

    if (relative == false)
      $LOAD_PATH.each do |path|
        begin
          files = Dir.entries(path)
        rescue Errno::ENOENT
          next
        end

        if files != nil
          file = "#{path}/#{filename}"
          break if File.exist?(file)
        end
      end
    end
    
    if File.exist?(file)
      code = ""
      File.open(file, "r") do |fileObj|
        while (line = fileObj.gets)
          code << line
        end
      end
      
    else
      raise Errno::ENOENT, "file #{filename} not found in #{$LOAD_PATH}"
    end
    
    code
  end
  
end
