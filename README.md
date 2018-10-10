# Galaaz

Galaaz is a system for tightly coupling Ruby and R.  Ruby is a powerful language, with
a large community, a very large set of libraries and great for web development.  However,
it lacks libraries for data science, statistics, scientific plotting and machine learning.
On the other hand, R is considered one of the most powerful languages for solving all of the
above problems.  Maybe the strongest competitor to R is Python with libraries such as NumPy,
Panda, SciPy, SciKit-Learn and a couple more.

With Galaaz we do not intend to re-implement any of the scientific libraries in R, we allow
for very tight coupling between the two languages to the point that the Ruby developer does
not need to know that there is an R engine running.  For this to happen we use new
technologies provided by Oracle, with GraalVM, TruffleRuby and FastR:

     GraalVM is a universal virtual machine for running applications written in JavaScript,
     Python 3, Ruby, R, JVM-based languages like Java, Scala, Kotlin, and LLVM-based languages
     such as C and C++.

     GraalVM removes the isolation between programming languages and enables interoperability in a
     shared runtime. It can run either standalone or in the context of OpenJDK, Node.js,
     Oracle Database, or MySQL.

     GraalVM allows you to write polyglot applications with a seamless way to pass values from one
     language to another. With GraalVM there is no copying or marshalling necessary as it is with
     other polyglot systems. This lets you achieve high performance when language boundaries are
     crossed. Most of the time there is no additional cost for crossing a language boundary at all.

     Often developers have to make uncomfortable compromises that require them to rewrite
     their software in other languages. For example:

      * “That library is not available in my language. I need to rewrite it.” 
      * “That language would be the perfect fit for my problem, but we cannot run it in our environment.” 
      * “That problem is already solved in my language, but the language is too slow.”
    
    With GraalVM we aim to allow developers to freely choose the right language for the task at
    hand without making compromises. 

Galaaz uses the low level Polyglot APIs to allow high level coupling between Ruby and R.
While in the low level Polyglot APIs, developers must be knowledgeable about the languages,
their boundaries and calling procedures, in Galaaz, developers use normal Ruby classes,
modules, etc. 

## The Polyglot Low Level API

TruffleRuby (the Polyglot implementation of Ruby) can access, through the Polyglot interface,
any other language available in the environment. For instance, in the code bellow, TruffleRuby
makes a call to JavaScript:

    require 'json'

    obj = {time: Time.now,   
           msg: 'Hello World',   
           payload: (1..10).to_a }

    encoded = JSON.dump(obj)

    js_obj = Polyglot.eval('js', 'JSON.parse').call(encoded)
    puts js_obj[:time] 
    puts js_obj[:msg] 
    puts js_obj[:payload].join(' ')

Calling R is similar to the above. For example, in R, method 'c' concatenates its arguments
making a vector:

    vec = Polyglot.eval('R', 'c').call(1, 2, 3) 
    puts vec[0] 
    p vec
    > 1
    > #<Truffle::Interop::Foreign@5d03df76> 

As can be seen, vec is a vector with the first element (indexed at 0 - Ruby indexing) is 1.
Inspecting vec, show that it is a Truffle::Interop object. Although it is possible to work with
Interop objects in a program, doing so is hard and error prone. Bellow, we show how integration of
Ruby and R can greatly simplify the development of Polyglot application.

# Galaaz Demo

## Prerequisites

* GraalVM (>= rc7)
* TruffleRuby
* FastR

The following R packages will be automatically installed when necessary, but could be installed prior
to the demo if desired:

* ggplot2
* gridExtra

Installation of R packages requires a development environment.  In Linux, the gnu compiler and
tools should be enough.  I am not sure what is needed on the Mac.

In order to run the 'specs' the following Ruby package is necessary:

* gem install rspec

## Preparation

* gem install galaaz

## Running the Demo

This demo was extracted from: http://r-statistics.co/Top50-Ggplot2-Visualizations-MasterList-R-Code.html.

On the console do

    > rake master_list:scatter_plot

Doing this will show the following plot:

![midwest-scatterplot](https://user-images.githubusercontent.com/3999729/46742999-87bc2480-cc7e-11e8-9f16-31c3437e4a58.PNG)

## The Code

In R, the code to generate this plot is the following

    # install.packages("ggplot2")
    # load package and data
    options(scipen=999)  # turn-off scientific notation like 1e+48
    library(ggplot2)
    theme_set(theme_bw())  # pre-set the bw theme.
    data("midwest", package = "ggplot2")
    # midwest <- read.csv("http://goo.gl/G1K41K")  # bkup data source

    # Scatterplot
    gg <- ggplot(midwest, aes(x=area, y=poptotal)) + 
          geom_point(aes(col=state, size=popdensity)) + 
          geom_smooth(method="loess", se=F) + 
          xlim(c(0, 0.1)) + 
          ylim(c(0, 500000)) + 
          labs(subtitle="Area Vs Population", 
               y="Population", 
               x="Area", 
               title="Scatterplot", 
               caption = "Source: midwest")

    plot(gg)


The following now, is the code in Ruby and the one that you have just ran if you typed in your
console: "rake master_list:scatter_plot"

    require 'galaaz'
    require 'ggplot'

    # load package and data
    R.options(scipen: 999)  # turn-off scientific notation like 1e+48
    R.theme_set(R.theme_bw)  # pre-set the bw theme.

    midwest = ~:midwest
    # midwest <- read.csv("http://goo.gl/G1K41K")  # bkup data source

    R.awt

    # Scatterplot
    gg = midwest.ggplot(E.aes(x: :area, y: :poptotal)) + 
         R.geom_point(E.aes(col: :state, size: :popdensity)) + 
         R.geom_smooth(method: "loess", se: false) + 
         R.xlim(R.c(0, 0.1)) + 
         R.ylim(R.c(0, 500000)) + 
         R.labs(subtitle: "Area Vs Population", 
                y: "Population", 
                x: "Area", 
                title: "Scatterplot", 
                caption: "Source: midwest")

    puts gg

Both codes are very similar.  The Ruby code requires the use of "R." before calling any functions,
for instance R function 'geom_point' becomes 'R.geom_point' in Ruby.  R named parameters such as
(col = state, size = popdensity), becomes in Ruby (col: :state, size: :popdensity).

One last
point that needs to be observed is the call to the 'aes' function.  In Ruby instead of doing
'R.aes', we use 'E.aes'.  The explanation of why E.aes is needed is an advanced topic in R and
depends on what is know as Non-standard Evaluation (NSE) in R.  In short, function 'aes' is lazily
evaluated in R, i.e., in R when calling geom_point(aes(col=state, size=popdensity)), function
geom_point receives as argument something similar to a string containing
'aes(col=state, size=popdensity)', and the aes function will be evaluated inside the geom_point
function.  In Ruby, there is no Lazy evaluation and doing R.aes would try to evaluate aes
immediately.  In order to delay the evaluation of function aes we need to use E.aes.  The
interested reader on NSE in R is directed to http://adv-r.had.co.nz/Computing-on-the-language.html.

## An extendion to the example

If both codes are so similar, then why would one use Ruby instead of R and what good is galaaz
after all?

Ruby is a modern OO language with numerous very useful constructs such as classes, modules, blocks,
procs, etc.  The example above focus on the coupling of both languages, and does not show the
use of other Ruby constructs.  In the following example, we will show a more complex example using
other Ruby constructs.



# Galaaz High Level Constructs

In R, the basic 

## Vectors


# Installation

* gu install ruby
* run post_install_hook.sh (as instructed)
* gu install R
* configure_fastr (as instructed)
* gu rebuild-images ruby (might not be necessary - time and cpu intensive)
* gem install galaaz
* execute 'galaaz' to see a slide show with many graphics
* execute 'galaaz -T' to see all available examples


