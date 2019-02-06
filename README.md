# Introduction

Galaaz is a system for tightly coupling Ruby and R. Ruby is a powerful language, with a large 
community, a very large set of libraries and great for web development. However, it lacks 
libraries for data science, statistics, scientific plotting and machine learning. On the 
other hand, R is considered one of the most powerful languages for solving all of the above 
problems. Maybe the strongest competitor to R is Python with libraries such as NumPy, 
Panda, SciPy, SciKit-Learn and a couple more.

# System Compatibility

* Oracle Linux 7
* Ubuntu 18.04 LTS
* Ubuntu 16.04 LTS
* Fedora 28
* macOS 10.14 (Mojave)
* macOS 10.13 (High Sierra)

# Dependencies

* TruffleRuby
* FastR


# Installation

* Install GrallVM (http://www.graalvm.org/)
* Install Ruby (gu install Ruby)
* Install FastR (gu install R)
* Install rake if you want to run the specs and examples (gem install rake)

# Usage

* Interactive shell: use 'gstudio' on the command line
  > gstudio
  
  galaaz >> vec = R.c(1, 2, 3, 4)
  galaaz >> puts vec
  [1] 1 2 3 4
  galaaz >> exit
  
* Run all specs
  > galaaz specs:all
  
* Run graphics slideshow (80+ graphics)
  > galaaz sthda:all
  
* Run labs from Introduction to Statistical Learning with R
  > galaaz islr:all

* See all available examples
  > galaaz -T
  
  Shows a list with all available executalbe tasks.  To execute a task, substitute the
  'rake' word in the list with 'galaaz'.  For instance, the following line shows up
  after 'galaaz -T'
  
  rake master_list:scatter_plot        # scatter_plot from:....
  
  execute
  
  > galaaz master_list:scatter_plot

# User Manual


[TO BE CONTINUED...]


# Contributing


* Fork it
* Create your feature branch (git checkout -b my-new-feature)
* Write Tests!
* Commit your changes (git commit -am 'Add some feature')
* Push to the branch (git push origin my-new-feature)
* Create new Pull Request

