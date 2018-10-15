# Introduction

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

## What does Galaaz mean

Galaaz is the Portuguese name for "Galahad".  From Wikipedia:

    Sir Galahad (/ˈɡæləhæd/; sometimes referred to as Galeas /ɡəˈliːəs/ or Galath /ˈɡæləθ/),
    in Arthurian legend, is a knight of King Arthur's Round Table and one of the three
    achievers of the Holy Grail. He is the illegitimate son of Sir Lancelot and Elaine of
    Corbenic, and is renowned for his gallantry and purity as the most perfect of all knights.
    Emerging quite late in the medieval Arthurian tradition, Sir Galahad first appears in the
    Lancelot–Grail cycle, and his story is taken up in later works such as the Post-Vulgate
    Cycle and Sir Thomas Malory's Le Morte d'Arthur. His name should not be mistaken with
    Galehaut, a different knight from Arthurian legend. 

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

## An extension to the example

If both codes are so similar, then why would one use Ruby instead of R and what good is galaaz
after all?

Ruby is a modern OO language with numerous very useful constructs such as classes, modules, blocks,
procs, etc.  The example above focus on the coupling of both languages, and does not show the
use of other Ruby constructs.  In the following example, we will show a more complex example using
other Ruby constructs.  This is certaily not a very well written and robust Ruby code, but
it give the idea of how Ruby and R are stronglyg coupled.

Let's imagine that we work in a corporation that has its plot themes.  So, it has defined a
'CorpTheme' module.  Plots in this corporation should not have grids, numbers in labels should
not use scientific notation and the prefered color is blue.

    # CorpTheme.rb
    # defines the corporate theme for all plots
    
    module CorpTheme

      #--------------------------------------------------------------------------------------
      # Defines the plot theme (visualization).  In this theme we remove major and minor
      # grids, borders and background.  We also turn-off scientific notation.
      #--------------------------------------------------------------------------------------

      def self.global_theme
    
        R.options(scipen: 999)  # turn-off scientific notation like 1e+48
    
        # remove major grids
        global_theme = R.theme(panel__grid__major: E.element_blank())
        # remove minor grids
        global_theme = global_theme + R.theme(panel__grid__minor: E.element_blank)
        # remove border
        global_theme = global_theme + R.theme(panel__border: E.element_blank)
        # remove background
        global_theme = global_theme + R.theme(panel__background: E.element_blank)
        # Change axis font
        global_theme = global_theme +
                       R.theme(axis__text: E.element_text(size: 8, color: "#000080"))
        # change color of axis titles
        global_theme = global_theme +
                       R.theme(axis__title: E.element_text(
                                 color: "#000080", 
                                 face: "bold",
                                 size: 8,
                                 hjust: 1))
      end
   
    end

We now define a ScatterPlot class:

    # ScatterPlot.rb
    # creates a scatter plot and allow some configuration
    
    class ScatterPlot

      attr_accessor :title
      attr_accessor :subtitle
      attr_accessor :caption
      attr_accessor :x_label
      attr_accessor :y_label
  
      #--------------------------------------------------------------------------------------
      # Initialize the plot with the data and the x and y variables
      #--------------------------------------------------------------------------------------

      def initialize(data, x:, y:)
        @data = data
        @x = x
        @y = y
      end

      #--------------------------------------------------------------------------------------
      # Define groupings by color and size
      #--------------------------------------------------------------------------------------

      def group_by(color:, size:)
        @color_by = color
        @size_by = size
      end

      #--------------------------------------------------------------------------------------
      # Add a smoothing line, and if confidence is true the add a confidence interval, if
      # false does not add the confidence interval
      #--------------------------------------------------------------------------------------

      def add_smoothing_line(method:, confidence: true)
        @method = method
        @confidence = confidence
      end
  
      #--------------------------------------------------------------------------------------
      # Creates the graph title, properly formated for this theme
      # @param title [String] The title to add to the graph
      # @return textGrob that can be included in a graph
      #--------------------------------------------------------------------------------------

      def graph_params(title: "", subtitle: "", caption: "", x_label: "", y_label: "")
        R.labs(
          title: title, 
          subtitle: subtitle, 
          caption: caption,
          y_label: y_label, 
          x_label: x_label, 
        )
      end

      #--------------------------------------------------------------------------------------
      # Prepare the plot's points
      #--------------------------------------------------------------------------------------

      def points
        params = {}
        params[:col] = @color_by if @color_by
        params[:size] = @size_by if @size_by
        R.geom_point(E.aes(params))
      end
      
      #--------------------------------------------------------------------------------------
      # Plots the scatterplot
      #--------------------------------------------------------------------------------------

      def plot
        R.awt
    
        puts @data.ggplot(E.aes(x: @x, y: @y)) +
          points + 
          R.geom_smooth(method: @method, se: @confidence) +
          R.xlim(R.c(0, 0.1)) +
          R.ylim(R.c(0, 500000)) + 
	  graph_params(title: @title,
                       subtitle: @subtitle, 
                       y_label: @y_label, 
                       x_label: @x_label, 
                       caption: @caption) +
          CorpTheme.global_theme
      end
  
    end

And this is the final code for making the scatter plot with the midwest data

    require 'galaaz'
    require 'ggplot'

    require 'CorpTheme'
    require 'ScatterPlot'

    sp = ScatterPlot.new(~:midwest, x: :area, y: :poptotal)
    sp.title = "Midwest Dataset - Scatterplot"
    sp.subtitle = "Area Vs Population"
    sp.caption = "Source: midwest"
    sp.x_label = "Area"
    sp.y_label = "Population"
    sp.group_by(color: :state, size: :popdensity)    # try sp.group_by(color: :state)
    # available methods: "lm", "glm", "loess", "gam"
    sp.add_smoothing_line(method: "glm") 
    sp.plot

    # require input from the user so that the script does not end removing the plot from
    # the screen
    a = gets.chomp  



## The Polyglot Low Level API

Galaaz uses the low level Polyglot APIs to allow high level coupling between Ruby and R.
While in the low level Polyglot APIs, developers must be knowledgeable about the languages,
their boundaries and calling procedures, in Galaaz, developers use normal Ruby classes,
modules, etc. 

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


# Galaaz High Level Constructs

[TO BE CONTINUED...] 

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


