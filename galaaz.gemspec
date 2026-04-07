# -*- coding: utf-8 -*-
require 'rubygems/platform'
require './version'
require 'date'

Gem::Specification.new do |gem|

  gem.name    = $gem_name
  gem.version = $version
  gem.date    = Date.today.to_s
  gem.executables << 'galaaz' << 'gstudio' << 'gknit' << 'gbookdown' << 'grun' << 'gknit-draft'
  gem.summary     = "Tightly coupling Ruby and R"
  gem.description = <<-EOF
Galaaz brings the full R ecosystem to Ruby developers. Galaaz 2.0 runs Ruby on JRuby and
talks to standard GNU R—the same R you use with CRAN and Bioconductor—in a separate
process. A bridge handles requests, results, and typing so you can drive R from Ruby
(for example calling R functions, loading packages, and working with R objects) without
giving up multithreaded JRuby for application code.

Like RinRuby, rpy2, or reticulate, Galaaz is a cross-language bridge; unlike embedding a
second interpreter in one VM, using GNU R means compiled R packages and Bioconductor work
as usual. Large tables can optionally flow through Apache Arrow on the R side when you use
the helpers described in the project documentation.

You need both JRuby and a working GNU R installation in PATH for the bridge to run.
EOF

  gem.authors  = ['Rodrigo Botafogo']
  gem.email    = 'rodrigo.a.botafogo@gmail.com'
  gem.homepage = 'http://github.com/rbotafogo/galaaz/wiki'
  gem.license = 'BSD-2-Clause'

  # This gem targets TruffleRuby only
  # gem.platform='java'

  # gem.add_runtime_dependency 'pry', '~> 0.10'

  gem.add_runtime_dependency('msgpack', '~> 1.0')

  gem.add_development_dependency('rspec', "~> 3.8")
  gem.add_development_dependency('simplecov', "~> 0.16")
  gem.add_development_dependency('rdoc', ">=6.1.2.1")
  # gem.add_development_dependency('rake', '~> 12.0')

  # Ship the manual and LaTeX style with the gem (blogs/manual, supporting Rmd/sty).
  # Collect all files that do not end with '~'
  fls = Dir['Rakefile', 'version.rb', 'README*', 'LICENSE*',
            'lib/**/*[!~]', 'specs/**/*[!~]', 'ext/**/*[!~]', 'examples/**/*[!~]',
            'r_requires/**/*[!~]', 'bin/**/*[!~]',
            'blogs/**/*[!~]', 'sty/**/*[!~]']
  gem.files = fls
  
  gem.metadata["yard.run"] = "yri" # use "yard" to build full HTML docs
  
end
