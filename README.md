---
title: "Galaaz Manual"
subtitle: "How to tightly couple Ruby and R in GraalVM"
author: "Rodrigo Botafogo"
tags: [Galaaz, Ruby, R, TruffleRuby, FastR, GraalVM, ggplot2]
date: "2019"
output:
  html_document:
    self_contained: true
    keep_md: true
  md_document:
    variant: markdown_github
  pdf_document:
    includes:
      in_header: "../../sty/galaaz.sty"
    keep_tex: yes
    number_sections: yes
    toc: true
    toc_depth: 2
fontsize: 11pt
---




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


```ruby
  vec = R.c(1, 2, 3, 4)
  puts vec
```

```
## [1] 1 2 3 4
```
  
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

# Basic Types

## Vectors

Vectors can be thought of as contiguous cells containing data. Cells are accessed through
indexing operations such as x[5]. Galaaz has six basic (‘atomic’) vector types: logical, 
integer, real, complex, string (or character) and raw. The modes and storage modes for the 
different vector types are listed in the following
table.

| typeof    | mode      | storage.mode |
|-----------|:---------:|-------------:|
| logical   | logical   |      logical |
| integer   | numeric   |      integer |
| double    | numeric   |       double |
| complex   | complex   |      comples |
| character | character |    character |
| raw       | raw       |          raw |

Single numbers, such as 4.2, and strings, such as "four point two" are still vectors, of length
1; there are no more basic types. Vectors with length zero are possible (and useful).
String vectors have mode and storage mode "character". A single element of a character
vector is often referred to as a character string.

To create a vector the 'c' (concatenate) method from the 'R' module should be used:


```ruby
@vec = R.c(1, 2, 3)
puts @vec
```

```
## [1] 1 2 3
```

Lets take a look at the type, mode and storage.mode of our vector @vec.  In order to print
this out, we are creating a data frame 'df' and printing it out.  A data frame, for those
not familiar with it, it basically a table.  Here we create the data frame and add the 
column name by passing named parameters for each column, such as 'typeof:', 'mode:' and
'storage__mode'.  You should also note here that the double underscore is converted to a '.'.

In R, the method used to create a data frame is 'data.frame', in Galaaz we use 'data__frame'.


```ruby
df = R.data__frame(typeof: @vec.typeof, mode: @vec.mode, storage__mode: @vec.storage__mode)
puts df
```

```
##    typeof    mode storage.mode
## 1 integer numeric      integer
```

If you want to create a vector with floating point numbers, then we need at least one of the
vector's element to be a float, such as 1.0.  R users should be careful, since in R a number
like '1' is converted to float and to have an integer the R developer will use '1L'. Galaaz
follows normal Ruby rules and the number 1 is an integer and 1.0 is a float.


```ruby
@vec = R.c(1.0, 2, 3)
puts @vec
```

```
## [1] 1 2 3
```


```ruby
df = R.data__frame(typeof: @vec.typeof, mode: @vec.mode, storage__mode: @vec.storage__mode)
puts df.kable
```

```
## <table>
##  <thead>
##   <tr>
##    <th style="text-align:left;"> typeof </th>
##    <th style="text-align:left;"> mode </th>
##    <th style="text-align:left;"> storage.mode </th>
##   </tr>
##  </thead>
## <tbody>
##   <tr>
##    <td style="text-align:left;"> double </td>
##    <td style="text-align:left;"> numeric </td>
##    <td style="text-align:left;"> double </td>
##   </tr>
## </tbody>
## </table>
```

In this next example we try to create a vector with a variable 'hello' that has not yet
being defined.  This will raise an exception that is printed out.  We get two return blocks,
the first with a message explaining what went wrong and the second with the full backtrace
of the error.


```ruby
vec = R.c(1, hello, 5)
```

```
## Message:
##  undefined local variable or method `hello' for RubyChunk:Class
```

```
## Message:
##  (eval):1:in `exec_ruby'
## /home/rbotafogo/desenv/galaaz/lib/util/exec_ruby.rb:122:in `instance_eval'
## /home/rbotafogo/desenv/galaaz/lib/util/exec_ruby.rb:122:in `exec_ruby'
## /home/rbotafogo/desenv/galaaz/lib/gknit/ruby_engine.rb:55:in `block in initialize'
## /home/rbotafogo/desenv/galaaz/lib/R_interface/ruby_callback.rb:77:in `call'
## /home/rbotafogo/desenv/galaaz/lib/R_interface/ruby_callback.rb:77:in `callback'
## (eval):3:in `function(...) {\n          rb_method(...)'
## unknown.r:1:in `in_dir'
## unknown.r:1:in `block_exec'
## /home/rbotafogo/lib/graalvm-ce-1.0.0-rc12/jre/languages/R/library/knitr/R/block.R:91:in `call_block'
## /home/rbotafogo/lib/graalvm-ce-1.0.0-rc12/jre/languages/R/library/knitr/R/block.R:6:in `process_group.block'
## /home/rbotafogo/lib/graalvm-ce-1.0.0-rc12/jre/languages/R/library/knitr/R/block.R:3:in `<no source>'
## unknown.r:1:in `withCallingHandlers'
## unknown.r:1:in `process_file'
## unknown.r:1:in `<no source>'
## unknown.r:1:in `<no source>'
## <REPL>:4:in `<repl wrapper>'
## <REPL>:1
```

## Graphics with ggplot


```ruby
require 'ggplot'

R.theme_set R.theme_bw

# Data Prep
mtcars = ~:mtcars
mtcars.car_name = R.rownames(:mtcars)
# compute normalized mpg 
mtcars.mpg_z = ((mtcars.mpg - mtcars.mpg.mean)/mtcars.mpg.sd).round 2
mtcars.mpg_type = mtcars.mpg_z < 0 ? "below" : "above"
mtcars = mtcars[mtcars.mpg_z.order, :all]
# convert to factor to retain sorted order in plot
mtcars.car_name = mtcars.car_name.factor levels: mtcars.car_name

# Diverging Barcharts
gg = mtcars.ggplot(E.aes(x: :car_name, y: :mpg_z, label: :mpg_z)) + 
     R.geom_bar(E.aes(fill: :mpg_type), stat: 'identity',  width: 0.5) +
     R.scale_fill_manual(name: "Mileage", 
                         labels: R.c("Above Average", "Below Average"), 
                         values: R.c("above": "#00ba38", "below": "#f8766d")) + 
     R.labs(subtitle: "Normalised mileage from 'mtcars'", 
            title: "Diverging Bars") + 
     R.coord_flip()

puts gg
```


![](/home/rbotafogo/desenv/galaaz/blogs/manual/manual_files/figure-html/diverging_bar.png)<!-- -->


[TO BE CONTINUED...]


# Contributing


* Fork it
* Create your feature branch (git checkout -b my-new-feature)
* Write Tests!
* Commit your changes (git commit -am 'Add some feature')
* Push to the branch (git push origin my-new-feature)
* Create new Pull Request

