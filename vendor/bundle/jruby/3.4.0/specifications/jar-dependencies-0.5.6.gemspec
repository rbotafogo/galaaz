# -*- encoding: utf-8 -*-
# stub: jar-dependencies 0.5.6 ruby lib

Gem::Specification.new do |s|
  s.name = "jar-dependencies".freeze
  s.version = "0.5.6".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["christian meier".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.description = "manage jar dependencies for gems and keep track which jar was already\nloaded using maven artifact coordinates. it warns on version conflicts and\nloads only ONE jar assuming the first one is compatible to the second one\notherwise your project needs to lock down the right version by providing a\nJars.lock file.\n".freeze
  s.email = ["mkristian@web.de".freeze]
  s.executables = ["lock_jars".freeze]
  s.files = ["exe/lock_jars".freeze]
  s.homepage = "https://github.com/mkristian/jar-dependencies".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\nif you want to use the executable lock_jars then install ruby-maven gem before using lock_jars\n\n  $ gem install ruby-maven -v '~> 3.9'\n\nor add it as a development dependency to your Gemfile\n\n   gem 'ruby-maven', '~> 3.9'\n\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "4.0.3".freeze
  s.summary = "manage jar dependencies for gems".freeze

  s.installed_by_version = "4.0.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.10".freeze])
  s.add_runtime_dependency(%q<ruby-maven>.freeze, ["~> 3.9".freeze])
end
