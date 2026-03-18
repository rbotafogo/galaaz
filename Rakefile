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

  # JRuby with JVM options required for Apache Arrow (same as bin/run_rspec / bin/run_example)
  @@jruby_opts = "-I lib -J--add-opens=java.base/java.nio=org.apache.arrow.memory.core,ALL-UNNAMED"

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
  # Run example or spec with JRuby (Galaaz 2.0 Shadow Bridge)
  #----------------------------------------------------------------------------------------

  def make_task
    if @rspec
      sh %{ jruby #{@@jruby_opts} -S rspec #{@filepath}.rb -f documentation }
    else
      sh %{ jruby #{@@jruby_opts} #{@filepath}.rb }
    end
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

# JRuby opts for ad-hoc tasks (same as MakeTask)
JRUBY_OPTS = "-I lib -J--add-opens=java.base/java.nio=org.apache.arrow.memory.core,ALL-UNNAMED"

# Run each .rb file in a directory (for groups that don't have an all.rb)
def run_each_file(file_list)
  file_list.each { |f| sh "jruby #{JRUBY_OPTS} #{f}" }
end

geoms = FileList['examples/sthda_ggplot/**/*.rb']
specs = FileList['specs/**/*.rb']
master_list = FileList['examples/50Plots_MasterList/**/*.rb']
islr = FileList['examples/islr/**/*.rb']
misc = FileList['examples/misc/**/*.rb']
blogs = Dir.entries("blogs")
bugs = FileList['bugs/**/*.rb']

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

#===========================================================================================
# Creates tasks for bug examples
#===========================================================================================

bugs.each do |f|
  task_name = File.basename(f, ".rb")
  dir_name = File.dirname(f)
  MakeTask.new("bugs", dir_name, task_name, false, <<-Desc)
    Executes misc #{task_name}
  Desc
end

#===========================================================================================
# Aggregate "all" tasks for groups that have multiple files (no single all.rb)
# sthda:all and islr:all already exist from MakeTask (they run all.rb in that dir)
#===========================================================================================

desc "Run all misc examples"
task "misc:all" do
  run_each_file(misc.to_a)
end

desc "Run all 50Plots_MasterList examples"
task "master_list:all" do
  run_each_file(master_list.to_a)
end

desc "Run all bug examples"
task "bugs:all" do
  run_each_file(bugs.to_a)
end

#===========================================================================================
# Run all example groups (sthda_ggplot, misc, 50Plots_MasterList, islr, bugs)
#===========================================================================================

desc "Run all examples (sthda_ggplot, misc, 50Plots_MasterList, islr, bugs)"
task "examples:all" => ["sthda:all", "misc:all", "master_list:all", "islr:all", "bugs:all"]

task :default => "examples:all"

#===========================================================================================
# Creates task for running gknit
#===========================================================================================

blogs.each do |dir|
  next if dir == '.' || dir == '..'
  blog_rmd = "blogs/#{dir}/#{dir}.Rmd"
  desc "run gknit to build #{dir} blog post"
  task "blog:#{dir}" do
    (sh %{ bin/gknit #{blog_rmd} } )
  end

end

#===========================================================================================
# Loads R and require libraries to run Galaaz
#===========================================================================================

desc 'Prepare R for running'
task :make_r do
  (sh %{ gu install r })
end

#===========================================================================================
# Makes a gem for publishing in RubyGems
#===========================================================================================

desc 'Makes a Gem'
task :make_gem do
  (sh %{ gem build #{$gem_name}.gemspec })
end

#===========================================================================================
# Publishes the gem at Rubygems
#===========================================================================================

desc 'Publish gem to rubygems'
task :publish_gem do
  (sh %{ gem push #{$gem_name}-#{$version}.gem })
end

=begin
desc 'default task'
task :default => [:install_gem]

desc 'Install the gem in the standard location'
task :install_gem => [:make_gem] do
  sh "gem install #{$gem_name}-#{$version}-java.gem"
end

desc 'Make documentation'
task :make_doc do
  sh "yard doc lib/*.rb lib/**/*.rb"
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/complete.rb']
  t.ruby_opts = ["--server", "-Xinvokedynamic.constants=true", "-J-Xmn512m", 
                 "-J-Xms1024m", "-J-Xmx1024m"]
  t.verbose = true
  t.warning = true
end

#===========================================================================================
# New Bridge Gatekeeper compilation tasks
#===========================================================================================

GATEKEEPER_DIR = "ext/new_bridge"
GATEKEEPER_SO  = "#{GATEKEEPER_DIR}/galaaz_gatekeeper.so"
GATEKEEPER_SRC = "#{GATEKEEPER_DIR}/galaaz_gatekeeper_phase1.cpp"

desc "Compile the Galaaz gatekeeper shared library (fast runtime loading)"
task :compile_gatekeeper do
  puts "Compiling gatekeeper shared library..."
  Dir.chdir(GATEKEEPER_DIR) do
    sh "make clean all"
  end
  puts "Gatekeeper compiled: #{GATEKEEPER_SO}"
end

desc "Clean gatekeeper compilation artifacts"
task :clean_gatekeeper do
  Dir.chdir(GATEKEEPER_DIR) do
    sh "make clean"
  end
end

desc "Run all New Bridge specs (auto-compiles gatekeeper if needed)"
task :new_bridge_specs => [:compile_gatekeeper] do
  sh %{ bundle exec rspec specs/new_bridge/ --format documentation }
end

desc "Run specific New Bridge phase specs"
namespace :new_bridge do
  task :phase0 => [:compile_gatekeeper] do
    sh %{ bundle exec rspec specs/new_bridge/phase0_protocol_spec.rb --format documentation }
  end
  
  task :phase1 => [:compile_gatekeeper] do
    sh %{ bundle exec rspec specs/new_bridge/phase1_req_ret_spec.rb --format documentation }
  end
  
  task :phase2 => [:compile_gatekeeper] do
    sh %{ bundle exec rspec specs/new_bridge/phase2_multi_instance_spec.rb --format documentation }
  end
  
  task :phase3 => [:compile_gatekeeper] do
    sh %{ bundle exec rspec specs/new_bridge/phase3_callbacks_spec.rb --format documentation }
  end
  
  task :all => [:compile_gatekeeper] do
    sh %{ bundle exec rspec specs/new_bridge/ --format documentation }
  end
end

=end
