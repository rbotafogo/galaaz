---
title: "How to do reproducible research in Ruby with gKnit"
author:
    - "Rodrigo Botafogo"
    - "Daniel Mossé - University of Pittsburgh"
tags: [Tech, Data Science, Ruby, R, GraalVM]
date: "20/02/2019"
output:
  html_document:
    self_contained: true
    keep_md: true
  pdf_document:
    includes:
      in_header: ["../../sty/galaaz.sty"]
    number_sections: yes
---



# Introduction

The idea of "literate programming" was first introduced by Donald Knuth in the 1980's.
The main intention of this approach was to develop software interspersing macro snippets,
traditional source code, and a natural language such as English that could be compiled into
executable code and at the same time easily read by a human developer. According to Knuth
"The practitioner of 
literate programming can be regarded as an essayist, whose main concern is with exposition 
and excellence of style."

The idea of literate programming evolved into the idea of reproducible research, in which
all the data, software code, documentation, graphics etc. needed to reproduce the research
and its reports could be included in a
single document or set of documents that when distributed to peers could be rerun generating
the same output and reports.

The R community has put a great deal of effort in reproducible research.  In 2002, Sweave was
introduced and it allowed mixing R code with Latex generating high quality PDF documents.  Those
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
it is very rare to see any R markdown document in the Ruby community.

In the Python community, the same effort to have code and text in an integrated environment
started also on the first decade of 2000. In 2006 iPython 0.7.2 was released.  In 2014,
Fernando Pérez, spun off project Jupyter from iPython creating a web-based interactive
computation environment.  Jupyter can now be used with many languages, including Ruby with the
iruby gem (https://github.com/SciRuby/iruby).  I am not sure if multiple languages can be used
in a Jupyter notebook.

# gKnitting a Document

This document describes gKnit.  gKnit uses Knitr and R markdown to knit a document in Ruby or R
and output it in any of the
available formats for R markdown.  gKnit runs atop of GraalVM, and Galaaz (an integration 
library between Ruby and R).  In gKnit, Ruby variables are persisted between chunks, making 
it an ideal solution for literate programming in this language.  Also, since it is based on 
Galaaz, Ruby chunks can have access to R variables and Polyglot Programming with Ruby and R
is quite natural.

Galaaz has been describe already in the following posts:

* https://towardsdatascience.com/ruby-plotting-with-galaaz-an-example-of-tightly-coupling-ruby-and-r-in-graalvm-520b69e21021.  
* https://medium.freecodecamp.org/how-to-make-beautiful-ruby-plots-with-galaaz-320848058857

This is not a blog post on rmarkdown, and the interested user is directed to the following links
for detailed information on its capabilities and use.

* https://rmarkdown.rstudio.com/ or
* https://bookdown.org/yihui/rmarkdown/ 

Here, we will describe quickly the main aspects of R markdown, so the user can start gKnitting
Ruby and R documents quickly.

## The Yaml header

An R markdown document should start with a Yaml header and be stored in a file with '.Rmd' extension.
This document has the following header for gKitting an HTML document.

```
---
title: "How to do reproducible research in Ruby with gKnit"
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

Document formatting can be done with simple markups such as:

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

Please, go to https://rmarkdown.rstudio.com/authoring_basics.html, for more R markdown formatting.

## Code Chunks

Running and executing Ruby and R code is actually what really interests us is this blog.  Inserting
a code chunk is done by adding code in a block delimited by three back ticks followed by a
block with the engine name (r, ruby, rb, include, others), an optional chunk_label and optional
options, as shown bellow:

````
```{engine_name [chunk_label], [chunk_options]}
```
````

for instance, let's add an R chunk to the document labeled 'first_r_chunk'.  In this 
example, we do not want the code to be shown in the document, so the option 
'echo=FALSE' is added.

````
```{r first_r_chunk, echo = FALSE}
```
````

A description of the available chunk options can be found in the documentation cited above.

For including a Ruby chunk, just change the name of the engine to ruby as follows:

````
```{ruby first_ruby_chunk}
```
````

In this example, the ruby chunk is called 'first_ruby_chunk'.  One important aspect of chunk
labels is that they cannot be duplicated.  If a chunk label is duplicated, knitting will
stop with an error.

### R chunks

Let's now add an R chunk to this document.  In this example, a vector 'r_vec' is created and
a new function 'reduce_sum' is defined.  The chunk specification is

````
```{r data_creation}
r_vec <- c(1, 2, 3, 4, 5)

reduce_sum <- function(...) {
  Reduce(sum, as.list(...))
}
```
````

and this is how it will look like once executed.  From now on, we will not show the chunk
definition any longer.



```r
r_vec <- c(1, 2, 3, 4, 5)

reduce_sum <- function(...) {
  Reduce(sum, as.list(...))
}
```

We can, possibly in another chunk, access the vector and call the function as follows:


```r
print(r_vec)
```

```
## [1] 1 2 3 4 5
```

```r
print(reduce_sum(r_vec))
```

```
## [1] 15
```
### R Graphics with ggplot

In the following chunk, we create a bubble chart in R and include it in this document.  The
data comes from the 'mpg' dataset that is natively available in R.


```r
# load package and data
library(ggplot2)
data(mpg, package="ggplot2")
# mpg <- read.csv("http://goo.gl/uEeRGu")

mpg_select <- mpg[mpg$manufacturer %in% c("audi", "ford", "honda", "hyundai"), ]

# Scatterplot
theme_set(theme_bw())  # pre-set the bw theme.
g <- ggplot(mpg_select, aes(displ, cty)) + 
  labs(subtitle="mpg: Displacement vs City Mileage",
       title="Bubble chart")

g + geom_jitter(aes(col=manufacturer, size=hwy)) + 
  geom_smooth(aes(col=manufacturer), method="lm", se=F)
```

![](/home/rbotafogo/desenv/galaaz/blogs/gknit/gknit_files/figure-html/bubble-1.png)<!-- -->

### Ruby chunks

In the same way that an R chunk is created, let's now create a Ruby chunk.  One important aspect
of Ruby is that in Ruby every evaluation of a chunk occurs on its own local scope, so, creating
a variable in a chunk will be out of scope in the next chunk.  To make sure that variables are
available between chunks, they should be made as instance variables for the chunk.

In this chunk, variable '\@a', '\@b' and '\@c' are standard Ruby variables and 
'\@vec' and '\@vec2' are two vectors created by calling the 'c' method on the R module.  
In Galalaaz, the R module allows us to access R functions transparently.  It should be clear 
that there is no requirement in gknit to call or use any R functions.  gKnit will 
knit standard Ruby code, or even general text without any code.


```ruby
@a = [1, 2, 3]
@b = "US$ 250.000"
@c = "Inline text in a Heading"

@vec = R.c(1, 2, 3)
@vec2 = R.c(10, 20, 30)
```

In this next block, variables '\@a', '\@vec' and '\@vec2' are used and printed.


```ruby
puts @a
puts @vec * @vec2
```

```
## 1
## 2
## 3
## [1] 10 40 90
```

### Accessing R from Ruby

One of the nice aspects of Galaaz on GraalVM, is that variables and functions defined in R, can
be easily accessed from Ruby.  This next chunk, reads data from R and uses the 'reduce_sum'
function defined previously.  To access an R variable from Ruby the '~' function should be
applied to the Ruby symbol representing the R variable.  Since the R variable is called 'r_vec',
in Ruby, the symbol to acess it is ':r_vec' and thus '~:r_vec' retrieves the value of the
variable.


```ruby
puts ~:r_vec
```

```
## [1] 1 2 3 4 5
```

In order to call an R function, the 'R.' module is used as follows


```ruby
puts R.reduce_sum(~:r_vec)
```

```
## [1] 15
```

### Inline Ruby code

Knitr allows inserting R inline by adding

. Unfortunately, this is not possible with Ruby code as there is no provision in knitr for
adding this kind of inline engine.  However, gKnit allows adding inline Ruby code with the
'rb' engine.  The following text will create and inline Ruby text:

````
This is some text with inline Ruby accessing variable \@b which has value:

```rb

```
and is followed by some other text!
````

The result of executing the above chunk is the following sentence with inline Ruby code

<div style="margin-bottom:50px;">
</div>

This is some text with inline Ruby accessing variable \@b which has value:

```rb

```
and is followed by some other text!

<div style="margin-bottom:50px;">
</div>

In an inline block, it is possible to execute multiple Ruby statements by adding a semicolon
between them:

````
Multiple statements in the 'rb' engine use semicolon:

```rb

```
````

<div style="margin-bottom:50px;">
</div>


Multiple statements in the 'rb' engine use semicolon:

```rb

```

<div style="margin-bottom:50px;">
</div>



```rb

```

Sometimes one wants to add an inline text in a heading.  To do that in Ruby the whole heading
needs to be returned by the inline Ruby engine.  For example the heading above, was created by
the following chunk:

````

```rb

```
````

Remember that variable '@\c' was defined in a previous Ruby chunk and is now being used to
create the section heading for this section.


### Plotting


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
# R.png
gg = mtcars.ggplot(E.aes(x: :car_name, y: :mpg_z, label: :mpg_z)) + 
     R.geom_bar(E.aes(fill: :mpg_type), stat: 'identity',  width: 0.5) +
     R.scale_fill_manual(name: "Mileage", 
                         labels: R.c("Above Average", "Below Average"), 
                         values: R.c("above": "#00ba38", "below": "#f8766d")) + 
     R.labs(subtitle: "Normalised mileage from 'mtcars'", 
            title: "Diverging Bars") + 
     R.coord_flip()
print gg
# R.dev__off
# R.include_graphics("Rplot001.png")
```

![](/home/rbotafogo/desenv/galaaz/blogs/gknit/gknit_files/figure-html/diverging_bar.png)<!-- -->

### Including Ruby files

R is a language that was created to be easy and fast for statisticians to use.  It was not a
language to be used for developing large systems.  Of course, there are large systems and
libraries in R, but the focus of the language is for developing statistical models and
distribute that to peers.

Ruby on the other hand, is a language for large software development.  Systems written in
Ruby will have dozens or hundreds of files.  In order to document a large system with
literate programming we cannot expect the developer to add all the files in a single '.Rmd'
file.  gKnit provides the 'include' chunk engine to include a Ruby file as if it had being
typed in the '.Rmd' file.

To include a file the following chunk should be created, where <filename> is the name of
the file to be include and where the extension, if it is '.rb', does not need to be added.
If the 'relative' option is not included, then it is treated as TRUE.  When 'relative' is
true, 'require_relative' semantics is used to load the file, when false, Ruby's $LOAD_PATH
is searched to find the file and it is 'require'd.

````
```{include <filename>, relative = <TRUE/FALSE>}
```
````

Here we include file 'model.rb' which is in the same directory of this blog.  This code
uses R 'caret' package to split a dataset in a train and test sets.

````
```{include model}
```
````


```include

```


```ruby
mtcars = ~:mtcars
model = Model.new(mtcars, percent_train: 0.8)
model.partition(:mpg)
puts model.train.head
puts model.test.head
```

```
## Message:
##  uninitialized constant GalaazUtil::Model
## Did you mean?  Module
```

```
## Message:
##  (eval):2:in `const_missing'
## (eval):2:in `exec_ruby'
## /home/rbotafogo/desenv/galaaz/lib/util/exec_ruby.rb:137:in `instance_eval'
## /home/rbotafogo/desenv/galaaz/lib/util/exec_ruby.rb:137:in `exec_ruby'
## /home/rbotafogo/desenv/galaaz/lib/gknit/ruby_engine.rb:55:in `block in initialize'
## /home/rbotafogo/desenv/galaaz/lib/R_interface/ruby_callback.rb:77:in `call'
## /home/rbotafogo/desenv/galaaz/lib/R_interface/ruby_callback.rb:77:in `callback'
## (eval):3:in `function(...) {\n          rb_method(...)'
## unknown.r:1:in `<promise>1841929680'
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

### Documenting Gems

gKnit also allows developers to document and load files that are not in the same directory
of the '.Rmd' file.  When using 'relative = FALSE' in a chunk header, gKnit will look for the
file in Ruby's \$LOAD_PATH and load it if found.

Here is an example of loading the 'continuation.rb' file from TruffleRuby.

````
```{include continuation, relative = FALSE}
```
````



```include

```

## Converting to PDF

One of the beauties of knitr is that the same input can be converted to many different outputs.
One very useful format, is, of course, PDF.  In order to converted an R markdown file to PDF
it is necessary to have LaTeX installed on the system.  We will not explain here how to
install LaTeX as there are plenty of documents on the web showing how to proceed.

gKnit comes with a simple LaTeX style file for gknitting this blog as a PDF document.  Here is
the Yaml header to generate this blog in PDF format instead of HTML:

```
---
title: "gKnit - Ruby and R Knitting with Galaaz in GraalVM"
author: "Rodrigo Botafogo"
tags: [Galaaz, Ruby, R, TruffleRuby, FastR, GraalVM, knitr, gknit]
date: "29 October 2018"
output:
  pdf_document:
    includes:
      in_header: ["../../sty/galaaz.sty"]
    number_sections: yes
---
```

# Conclusion

One of the promises of GraalVM is that users/developers will be able to use the best tool
for their task at hand, independently of the programming language the tool was written.  Galaaz
and gKnit are not trivial implementations atop the GraalVM and Truffle interop messages;
however, the time and effort it took to wrap Ruby over R - Galaaz - (not finished yet) or to
wrap Knitr with gKnit is a fraction of a fraction of a fraction of the time require to
implement the original tools.  Trying to reimplement all R packages in Ruby would require the
same effort it is taking Python to implement NumPy, Panda and all supporting libraries and it
is unlikely that this effort would ever be done.  GraalVM has allowed Ruby to profit "almost
for free" from this huge set of libraries and tools that make R one of the most used
languages for data analysis and machine learning.

More interesting though than being able to wrap the R libraries with Ruby, is that Ruby adds
value to R, by allowing developers to use powerful and modern constructs for code reuse that
are not the strong points of R.  As shown in this blog, R and Ruby can easily communicate
and R can be structured in classes and modules in a way that greatly expands its power and
readability.

# Installing gKnit

## Prerequisites

* GraalVM (>= rc8)
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

* gknit <filename>
