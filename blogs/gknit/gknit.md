---
title: "gKnit - Ruby and R Knitting with Galaaz in GraalVM"
author: "Rodrigo Botafogo"
tags: [Galaaz, Ruby, R, TruffleRuby, FastR, GraalVM, knitr]
date: "19 October 2018"
output:
  html_document:
    self_contained: true
    keep_md: true
---



# Introduction

The idea of "literate programming" was first introduced by Donald Knuth in the 1980's.
The main intention of this approach was to develop software interspersing macro snippets,
traditional source code, and a natural language such as English that could be compiled into
executable code and at the same time easily read by a human developer. According to Knuth
"The practitioner of 
literate programming can be regarded as an essayist, whose main concern is with exposition 
and excellence of style."

The idea of literate programming envolved into the idea of reproducible research, in which
all the data, software code, documentation, graphics etc. needed to reproduce the research
and its reports could be included in a
single document or set of documents that when distributed to peers could be rerun generating
the same output and reports.

The R community has put a great deal of effort in reproducible research.  In 2002, Sweave was
introduced and it allowed mixing R code with Latex generating hight quality PDF documents.  Those
documents could include the code, the result of executing the code, graphics and text.  This
contained the whole narrative to reproduce the research.  But Sweave had many problems and in
2012, Knitr, developed by Yihui Xie from RStudio was released, solving many of the long lasting
problems from Sweave and including in one single package many extensions and add-on packages that
were necessary for Sweave.

With Knitr, R markdown was also developed, an extension the the
Markdown format.  With R markdown and Knitr it is possible to generate reports in a multitude
of formats such as HTML, markdown, Latex, PDF, dvi, etc.  R markdown also allows the use of
multiple programming languages in the same document.  In R markdown text is interspersed with
code chunks that can be executed and both the code as the result of executing the code can become
part of the final report.  Although R markdown allows multiple programming languages in the
same document, only R and Python (with
the reticulate package) can persist variables between chunks.  For other languages, such as
Ruby, every chunk will start a new process and thus all data is lost between chunks, unless it
is somehow stored in a data file that is read by the next chunk.

Being able to persist data
between chunks is critical for literate programming otherwise the flow of the narrative is lost
by all the effort of having to save data and then reload it. Probably, because of this impossibility,
it is very rare to see any R markdown document document in the Ruby community.  

In the Python community, the same effort to have code and text in an integrated environment
started also on the first decade of 2000. In 2006 iPython 0.7.2 was released.  In 2014,
Fernando Pérez, spun off project Jupyter from iPython creating a web-based interactive
computation environment.  Jupyter can now be used with many languages, including Ruby with the
iruby gem (https://github.com/SciRuby/iruby).  I am not sure if multiple languages can be used
in a Jupyter notebook.

# gKnitting a Document

This document describes gKnit.  gKnit uses Knitr and R markdown to knit a document in Ruby or R
and output it in any of the
available formats for R markdown.  The only difference between gKnit and normal Knitr documents
is that gKnit runs atop of GraalVM, and Galaaz (an integration library between Ruby and R).
Another blog post on Galaaz and its integration with ggplot2 can be found at:
https://towardsdatascience.com/ruby-plotting-with-galaaz-an-example-of-tightly-coupling-ruby-and-r-in-graalvm-520b69e21021.  With Galaaz, gKnit can knit documents in Ruby and R and both
Ruby and R execute on the same process and memory, variables, classes, etc.
will be preserved between chunks of code.

This is not a blog post on rmarkdown, and the interested user is directed to
https://rmarkdown.rstudio.com/ or
https://bookdown.org/yihui/rmarkdown/ for detailed information on its capabilities and use.
Some of the features available for R code
chunks are not yet available for Ruby code.  But we are working for removing any limitations.
Here, we will describe quickly the main aspects of R markdown, so the user can start gKnitting
simple documents quickly.

## The Yaml header

An R markdown document should start with a Yaml header and be stored in a file with '.Rmd' extension.
This document has the following header for gKitting an HTML document.

```
---
title: "gKnit - Ruby and R Knitting with Galaaz in GraalVM"
author: "Rodrigo Botafogo"
tags: [Galaaz, Ruby, R, TruffleRuby, FastR, GraalVM, knitr, gknit]
date: "29 October 2018"
output:
  html_document:
    keep_md: true
---
```

For more information on the options in the Yaml header, check https://bookdown.org/yihui/rmarkdown/html-document.html.

## R Markdown formatting

Document formating can be done with simple markups such as:

### Headers

```
# Header 1

## Header 2

### Header 3

```

### Lists

```
Unordered lists:

* Item 1
* Item 2
    + Item 2a
    + Item 2b
```

```
Ordered Lists

1. Item 1
2. Item 2
3. Item 3
    + Item 3a
    + Item 3b
```

Please, go to https://rmarkdown.rstudio.com/authoring_basics.html, for more R markdown formating.

## Code Chunks

Running and executing Ruby and R code is actually what really interests us is this blog.  Inserting
a code chunk is done by adding the following line in the document:

````
```{engine_name [chunk_label], [chunk_options]}
```
````

for instance, to add an R chunk the document add

````
```{r first_r_chunk, echo = FALSE}
```
````

A description of the available chunk options can be found in the documentation cited above.

For including a Ruby chunk, just change the name of the engine to ruby as follows:

````
```{ruby first_ruby_chunk}
```

### R chunks


In order to add R code to a text, a code chunk is added with the following markup:

So, for instance, here we create an R code chunk setting a variable to a vector:

````
```{r, eval=TRUE}
r_vec <- c(1, 2, 3)
```
````


```r
r_vec <- c(1, 2, 3)
# Using an example vector "arg"
arg = c(1, 2, 3, 4, 5)
redundant_sum <- function(...) {
  Reduce(sum, as.list(...))
}
redundant_sum(arg)
```

```
## [1] 15
```


### Ruby chunks


```ruby
$a = [1, 2, 3]
$vec = R.c(1, 2, 3)
$vec2 = R.c(10, 20, 30)
$b = "R$ 250.000"
$c = "class Array"
```

I'm now testing the ruby engine with more comples code in it.

```ruby
puts $a
puts $vec * $vec2
```

```
## 1
## 2
## 3
## [1] 10 40 90
```
we need to check what the result is gona be


```ruby
a = String.new("hello there")
b = [1, 2, 3]
puts a
puts b
```

```
## hello there
## 1
## 2
## 3
```

### Accessing R from Ruby


### Inline Ruby code

This is some text with inline Ruby
R$ 250.000
is this lost will this continue?

This is also possible
1
2
3
R$ 250.000
what comes out??

And what about this?

# class Array
Any problems surround it with text?

### Including Ruby files


```include
require 'galaaz'
 # require 'awesome_print'
 
 # Loads the R 'caret' package.  If not present, installs it 
 R.install_and_loads 'caret'
 
 class Model
   
   attr_reader :data
   attr_reader :test
   attr_reader :train
 
   #==========================================================
   #
   #==========================================================
   
   def initialize(data, percent_train:, seed: 123)
 
     R.set__seed(seed)
     @data = data
     @percent_train = percent_train
     @seed = seed
     
   end
 
   #==========================================================
   #
   #==========================================================
 
   def partition
 
     train_index =
       R.createDataPartition(@data.mpg, p: @percet_train,
                             list: false, times: 1)
     @train = @data[train_index, :all]
     @test = @data[-train_index, :all]
     
   end
   
 end
 
 mtcars = ~:mtcars
 model = Model.new(mtcars, percent_train: 0.8)
 model.partition
 puts model.train.head
 puts model.test.head
 

```

```
##                    mpg cyl  disp  hp drat    wt  qsec vs am gear carb
## Datsun 710        22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
## Hornet 4 Drive    21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
## Hornet Sportabout 18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
## Merc 240D         24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
## Merc 280          19.2   6 167.6 123 3.92 3.440 18.30  1  0    4    4
## Merc 280C         17.8   6 167.6 123 3.92 3.440 18.90  1  0    4    4
##                mpg cyl  disp  hp drat    wt  qsec vs am gear carb
## Mazda RX4     21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4
## Mazda RX4 Wag 21.0   6 160.0 110 3.90 2.875 17.02  0  1    4    4
## Valiant       18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
## Duster 360    14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
## Merc 230      22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
## Merc 450SE    16.4   8 275.8 180 3.07 4.070 17.40  0  0    3    3
```


# Installing gKnit

## Prerequisites

* GraalVM (>= rc7)
* TruffleRuby
* FastR

The following R packages will be automatically installed when necessary, but could be installed prior
to using gKnit if desired:

* ggplot2
* gridExtra
* knitr

Installation of R packages requires a development environment and can be time consuming.  In Linux,
the gnu compiler and tools should be enough.  I am not sure what is needed on the Mac.

## Preparation

* gem install galaaz

## Usage

* gknit [filename]
