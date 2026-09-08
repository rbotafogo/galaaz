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
require 'shellwords'

require_relative 'version'
require_relative 'lib/galaaz_ruby'

#----------------------------------------------------------------------------------------
#
#----------------------------------------------------------------------------------------

class MakeTask < Rake::TaskLib

  # Ruby prefix for running Galaaz. Uses `ruby` on PATH unless GALAAZ_RUBY is set.
  # JVM flags only when the selected interpreter is JRuby (see lib/galaaz_ruby.rb).
  def self.galaaz_ruby_invocation
    GalaazRuby.shell_invocation('lib')
  end

  # Alias kept for existing call sites; same as galaaz_ruby_invocation.
  def self.galaaz_jruby_invocation
    galaaz_ruby_invocation
  end

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
  # Run example or spec with Galaaz Ruby (ruby on PATH; GALAAZ_RUBY overrides)
  #----------------------------------------------------------------------------------------

  def make_task
    inv = MakeTask.galaaz_ruby_invocation
    if @rspec
      sh %{ #{inv} -S bundle exec rspec #{@filepath}.rb -f documentation }
    else
      sh %{ #{inv} -S bundle exec ruby #{@filepath}.rb }
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

# Run each .rb file in a directory (for groups that don't have an all.rb)
def run_each_file(file_list)
  inv = MakeTask.galaaz_ruby_invocation
  file_list.each { |f| sh "#{inv} -S bundle exec ruby #{f}" }
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
# Release helpers: keep version.rb and Gemfile.lock in sync (CI frozen install)
#===========================================================================================

namespace :release do
  desc 'Fail if version.rb does not match the PATH galaaz version in Gemfile.lock'
  task :check do
    ruby 'bin/check_gemfile_lock_version'
  end

  desc 'Set version.rb to VERSION=x.y.z and refresh Gemfile.lock (bundle lock)'
  task :bump do
    new_ver = ENV['VERSION'].to_s.strip
    abort 'Usage: rake release:bump VERSION=x.y.z' if new_ver.empty?
    ruby 'bin/release_bump', new_ver
  end
end

#===========================================================================================
# Makes a gem for publishing in RubyGems
#===========================================================================================

desc 'Makes a Gem'
task :make_gem => 'release:check' do
  (sh %{ gem build #{$gem_name}.gemspec })
end

#===========================================================================================
# Publishes the gem at Rubygems
#===========================================================================================

desc 'Publish gem to rubygems'
task :publish_gem => 'release:check' do
  (sh %{ gem push #{$gem_name}-#{$version}.gem })
end

#===========================================================================================
# NewBridge gatekeeper + combined spec run (JRuby; see also bin/run_all_rspec)
#===========================================================================================

desc 'Compile the NewBridge gatekeeper shared library (ext/new_bridge; incremental make)'
task :compile_gatekeeper do
  Dir.chdir('ext/new_bridge') { sh 'make all' }
end

desc 'Run specs/ and new_bridge_specs/ with SimpleCov (same idea as bin/run_all_rspec; GALAAZ_RUBY overrides)'
task :specs_all_with_new_bridge => [:compile_gatekeeper] do
  root = File.expand_path(__dir__)
  inv = MakeTask.galaaz_ruby_invocation
  top = Dir[File.join(root, 'specs', '*_spec.rb')] + Dir[File.join(root, 'specs', '*.spec.rb')]
  files = top.sort.map { |p| Shellwords.escape(p) }.join(' ')
  nb = Shellwords.escape(File.join(root, 'new_bridge_specs'))
  helper = Shellwords.escape(File.join(root, 'specs', 'spec_helper.rb'))
  sh %{ #{inv} -r #{helper} -S bundle exec rspec #{files} #{nb} }
end
