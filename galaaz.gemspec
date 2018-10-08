# -*- coding: utf-8 -*-
require 'rubygems/platform'
require './version'

Gem::Specification.new do |gem|

  gem.name    = $gem_name
  gem.version = $version
  gem.date    = Date.today.to_s
  gem.executables << 'galaaz'
  gem.summary     = "Tightly coupling Ruby and R"
  gem.description = <<-EOF
Galaaz brings the power of R to the Ruby community. Galaaz 
is based on TruffleRuby and FastR, GraalVM-based interpreters for Ruby and the R language 
for statistical computing respectively.

Over the past two decades, the R language for statistical computing has emerged as the de 
facto standard for analysts, statisticians, and scientists. Today, a wide range of 
enterprises – from pharmaceuticals to insurance – depend on R for key business uses. FastR 
is a new implementation of the R language and environment for the Graal Virtual Machine.

Galaaz tightly couples Ruby and R and allows the use of R inside a Ruby script. In a sense, 
Galaaz is similar to other solutions such as RinRuby, Rpy2, PipeR, and reticulate 
(https://blog.rstudio.com/2018/03/26/reticulate-r-interface-to-python/). However, since 
Galaaz couples TruffleRuby and FastR that both target the JVM there is no need to integrate 
both solutions and there is no need to send data between Ruby and R, as it all resides in 
the same VM. 

Further, installation of Galaaz does not require the installation of GNU R. When installing
GraalVM, just install TruffleRuby and FastR.
EOF

  gem.authors  = ['Rodrigo Botafogo']
  gem.email    = 'rodrigo.a.botafogo@gmail.com'
  gem.homepage = 'http://github.com/rbotafogo/galaaz/wiki'
  gem.license = 'BSD-2-Clause'

  # This gem targets TruffleRuby only
  # gem.platform='java'

  gem.add_development_dependency('rspec', "~> 3.8")
  gem.add_development_dependency('simplecov', "~> 0.16")
  gem.add_development_dependency('rdoc', "~> 5.0")
  gem.add_development_dependency('rake', '~> 12.0')

  # ensure the gem is built out of versioned files
  fls = Dir['Rakefile', 'version.rb', 'README*', 'LICENSE*',
            'lib/**/*', 'specs/**/*', 'examples/**/*', 'r_requires/**/*',
            'bin/**/*']
  gem.files = fls

  gem.metadata["yard.run"] = "yri" # use "yard" to build full HTML docs
  
end
