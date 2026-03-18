#
# Copyright (C) 2013 Christian Meier
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'maven'
require 'maven/ruby/maven'
require 'maven/ruby/version'

module RubyMaven

  def self.exec( *args )
    if File.exist?('settings.xml') and not args.member?('-s') and not args.member?('--settings')
      args << '-s'
      args << 'settings.xml'
    end
    if args.member?('-version') or args.member?('--version') or args.member?('-v')
      launch( '--version' )
    elsif defined? Bundler
      # it can be switching from ruby to jruby with invoking maven
      # just keep it clean
      if Bundler.respond_to?(:with_unbundled_env)
        Bundler.with_unbundled_env do
          launch( *args )
        end
      else
        Bundler.with_clean_env do
          launch( *args )
        end
      end
    else
      launch( *args )
    end
  end

  def self.dir
    @dir ||= File.expand_path( '../../', __FILE__ )
  end

  def self.version
    polyglot_version = begin
                         xml = File.read( File.join( dir, '.mvn/extensions.xml' ) )
                         xml.sub( /.*<version>/m, '' ).sub(/<\/version>.*/m, '' )
                       rescue Errno::ENOENT => e
                         Maven::Ruby::POLYGLOT_VERSION
                       end
  end

  def self.launch( *args )
    if args.member?('--version') or args.member?('--show-version')
      warn "Polyglot Maven Extension #{Maven::Ruby::POLYGLOT_VERSION} via ruby-maven #{Maven::Ruby::VERSION}"
    end
    old_maven_home = ENV['M2_HOME']
    ENV['M2_HOME'] = Maven.home
    ext_dir = File.join(Maven.lib, 'ext')
    FileUtils.mkdir_p(ext_dir)
    local_dir = File.join(__dir__, 'extensions')
    Dir.new(local_dir).select do |file|
      file =~ /.*\.jar$/
    end.each do |jar|
      source = File.join(local_dir, jar)
      if jar =~ /polyglot-.*-#{Maven::Ruby::POLYGLOT_VERSION}.jar/
        # ruby maven defines the polyglot version and this jar sets up its classpath
        # i.e. on upgrade or downgrade the right version will be picked
        FileUtils.cp(source, File.join(ext_dir, jar.sub(/-[0-9.]*(-SNAPSHOT)?.jar$/, '.jar')))
      elsif not File.exist?(File.join(ext_dir, jar)) and not jar =~ /jruby-(core|stdlib).*/
        # jar files are immutable as they carry the version
        warn jar
        FileUtils.cp(source, File.join(ext_dir, jar.sub(/-9.4.5.0/, '')))
      end
    end

    Maven.exec( *args )

  ensure
    ENV['M2_HOME'] = old_maven_home
  end
end
