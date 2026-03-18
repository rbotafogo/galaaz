# -*- encoding: utf-8 -*-
# stub: ruby-maven 3.9.3 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-maven".freeze
  s.version = "3.9.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Christian Meier".freeze]
  s.date = "2024-12-10"
  s.description = "maven support for ruby DSL pom files. MRI needs java/javac installed.".freeze
  s.email = ["m.kristian@web.de".freeze]
  s.executables = ["rmvn".freeze]
  s.files = ["bin/rmvn".freeze]
  s.homepage = "https://github.com/jruby/ruby-maven".freeze
  s.licenses = ["EPL-2.0".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubygems_version = "3.2.29".freeze
  s.summary = "maven support for ruby projects".freeze

  s.installed_by_version = "4.0.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<ruby-maven-libs>.freeze, ["~> 3.9.9".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.3".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.3".freeze])
end
