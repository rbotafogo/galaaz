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

require_relative 'version'

#----------------------------------------------------------------------------------------
#
#----------------------------------------------------------------------------------------

class MakeTask < Rake::TaskLib

  # Create class variables for the polyglot options and libs
  @@polyglot_options = "--polyglot --jvm -Xsingle_threaded"
  @@libs = "-Ilib/" # -Ir_requires/"

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------
  
  def initialize(group, dir_name, task_name, rspec,
                 description = "#{group}:#{task_name}")
    @name = "#{group}:#{task_name}"
    @filepath = "#{dir_name}/#{task_name}"
    @group = group
    @description = description
    @rspec = rspec
    
    yield self if block_given?
    define
  end

  #----------------------------------------------------------------------------------------
  # Actual TruffleRuby command (with options) to run the example
  #----------------------------------------------------------------------------------------

  def make_task
    @rspec ?
      (sh %{ ruby #{@@polyglot_options} #{@@libs} -S rspec #{@filepath}.rb -f documentation }) :
      (sh %{ ruby #{@@polyglot_options} #{@@libs} -S #{@filepath}.rb })
  end

  #----------------------------------------------------------------------------------------
  # Creates the tasks.  It the task is already defined, then append to it (enhance)
  #----------------------------------------------------------------------------------------

  def define
    desc @description
    Rake::Task.task_defined?(@name) ? Rake::Task[@name].enhance { make_task } :
      (task(@name) { make_task } )
  end
  
end

geoms = FileList['examples/sthda_ggplot/**/*.rb']
specs = FileList['specs/**/*.rb']
master_list = FileList['examples/50Plots_MasterList/**/*.rb']
islr = FileList['examples/islr/**/*.rb']
misc = FileList['examples/misc/**/*.rb']

#===========================================================================================
# Creates tasks for all specs.
# Running 'rake specs:all' will run all specs
#===========================================================================================

specs.each do |f|
  task_name = File.basename(f, ".rb")
  dir_name = File.dirname(f)
  MakeTask.new("specs", dir_name, task_name, true, <<-Desc)
    Executes spec #{task_name}
  Desc
end
  
#===========================================================================================
# Creates tasks for ggplot graphics from sthda website
# Running 'rake sthda:all' will run a slide show of all plots available 
#===========================================================================================

geoms.each do |f|
  task_name = File.basename(f, ".rb")
  dir_name = File.dirname(f)
  MakeTask.new("sthda", dir_name, task_name, false, <<-Desc)
    ggplot for #{task_name}
  Desc
end

#===========================================================================================
# Creates tasks for ggplot graphics from r-statistics.co website
# Running 'rake master_list:all' will run a slide show of all plots available 
#===========================================================================================

master_list.each do |f|
  task_name = File.basename(f, ".rb")
  dir_name = File.dirname(f)
  MakeTask.new("master_list", dir_name, task_name, false, <<-Desc)
     #{task_name} from: http://r-statistics.co/Top50-Ggplot2-Visualizations-MasterList-R-Code.html
  Desc
end

#===========================================================================================
# Creates tasks for the Introduction to Statistical Learning book labs
# Running 'rake islr:all' will run all specs
#===========================================================================================

islr.each do |f|
  task_name = File.basename(f, ".rb")
  dir_name = File.dirname(f)
  MakeTask.new("islr", dir_name, task_name, true, <<-Desc)
    Executes islr #{task_name}
  Desc
end

#===========================================================================================
# Creates tasks for misc examples
# Running 'rake misc:all' will run all specs
#===========================================================================================

misc.each do |f|
  task_name = File.basename(f, ".rb")
  dir_name = File.dirname(f)
  MakeTask.new("misc", dir_name, task_name, false, <<-Desc)
    Executes misc #{task_name}
  Desc
end

task :default => "sthda:all"


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
