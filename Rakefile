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

require 'rake/tasklib'
require 'rake/testtask'
# require_relative 'version'

geoms = FileList['examples/sthda_ggplot/**/*.rb']
specs = FileList['specs/**/*.rb']

polyglot_options = "--polyglot --jvm -Xsingle_threaded"
libs = "-Ilib/ -Ir_requires/"

# task :default => "tests:specs"

#===========================================================================================
# Creates tasks for all specs.
# Running 'rake specs:all' will run all specs
#===========================================================================================

specs.each do |f|
  task_name = File.basename(f, ".rb")
  dir_name = File.dirname(f)
  desc "Running spec #{task_name}"
  task "specs:#{task_name}" do
    sh %{ ruby #{polyglot_options} #{libs} -S rspec #{dir_name}/#{task_name}.rb -f documentation }  
  end
end

#===========================================================================================
# Creates tasks for ggplot graphics from sthda website
# Running 'rake sthda:all' will run a slide show of all plots available 
#===========================================================================================

geoms.each do |f|
  task_name = File.basename(f, ".rb")
  dir_name = File.dirname(f)
  desc "Running geom #{task_name}"
  task "sthda:#{task_name}" do
    sh %{ ruby #{polyglot_options} #{libs} -S #{dir_name}/#{task_name}.rb }  
  end
end

#===========================================================================================
namespace 'examples' do

  #-------------------------------------------------------------------------------------------
  desc "Master list of nice ggplot graphics extracted from http://r-statistics.co/Top50-Ggplot2-Visualizations-MasterList-R-Code.html"
  task :master_list do
    Dir.chdir "examples/50Plots_MasterList"
    sh %{ ruby #{polyglot_options} #{libs} -S master_list.rb }  
  end

  #-------------------------------------------------------------------------------------------
  desc "Examples from the book 'Introduction to Statistical Learning'"
  task :islr do
    Dir.chdir "examples/islr"
    sh %{ ruby #{polyglot_options} #{libs} -S rspec islr.rb -f documentation }  
  end

end


=begin
name = "#{$gem_name}-#{$version}.gem"

desc 'default task'
task :default => [:install_gem]

desc 'Makes a Gem'
task :make_gem do
  sh "gem build #{$gem_name}.gemspec"
end

desc 'Install the gem in the standard location'
task :install_gem => [:make_gem] do
  sh "gem install #{$gem_name}-#{$version}-java.gem"
end

desc 'Make documentation'
task :make_doc do
  sh "yard doc lib/*.rb lib/**/*.rb"
end

desc 'Push project to github'
task :push do
  sh "git push origin master"
end

desc 'Push gem to rubygem'
task :push_gem do
  sh "push #{name} -p $http_proxy"
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/complete.rb']
  t.ruby_opts = ["--server", "-Xinvokedynamic.constants=true", "-J-Xmn512m", 
                 "-J-Xms1024m", "-J-Xmx1024m"]
  t.verbose = true
  t.warning = true
end

=end
