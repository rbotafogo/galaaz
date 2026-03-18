# -*- mode:ruby -*-

gemspec
properties 'push.skip': true, 'jruby.version': '9.3.1.0'

load File.join( basedir,'lib/maven/ruby/version.rb')

jar "io.takari.polyglot:polyglot-ruby:#{Maven::Ruby::POLYGLOT_VERSION}", scope: :provided

execute 'cleanup extensions', 'initialize' do |ctx|
  FileUtils.rm_rf "#{ctx.project.build.directory}/../lib/extensions"
end

plugin :dependency do

  execute_goal(:"copy-dependencies",
               phase: 'prepare-package',
               includeScope: :provided,
               includeGroupIds: 'io.takari.polyglot',
               outputDirectory: '${project.build.directory}/../lib/extensions')

end

profile :id => :release do
  properties 'maven.test.skip' => true, 'invoker.skip' => true
  properties 'push.skip' => false
  build do
    default_goal :deploy
  end
end

# vim: syntax=Ruby
