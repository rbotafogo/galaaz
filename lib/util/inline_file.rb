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

require 'find'

module GalaazUtil

  def self.find_directories(pwd = Dir.pwd)
    directories = []
    begin
      Find.find(pwd) do |path|
        Find.prune if path.include? '.git'
        next unless File.directory?(path)
        directories << path
      end
    rescue
      puts "Error reading files."
    end
    directories
  end
  
  def self.find_files(pwd = Dir.pwd)
    files = []
    begin
      Find.find(pwd) do |path|
        Find.prune if path.include? '.git'
        next if path.include? 'picasa'
        next unless File.file?(path)
        files << path
      end
    rescue
      puts "Error reading files."
    end
    files
  end

  def self.inline_file(filename, pwd = Dir.pwd)
    file = "#{pwd}/#{filename}"
    if File.exist?(file)
      code = []
      File.open(file, "r") do |fileObj|
        while (line = fileObj.gets)
          code << line
        end
      end
      code
    else
      puts "File #{file} not found"
    end
  end

end
