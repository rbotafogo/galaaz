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

# gKnitting a Document

This manual has been formatted usign gKnit.  gKnit uses Knitr and R markdown to knit 
a document in Ruby or R and output it in any of the available formats for R markdown.  
gKnit runs atop of GraalVM, and Galaaz.  In gKnit, Ruby variables are persisted between 
chunks, making it an ideal solution for literate programming.  
Also, since it is based on Galaaz, Ruby chunks can have access to R variables and Polyglot 
Programming with Ruby and R is quite natural.

gknit was describe in more depth in:

* xxx.xxxx.xxx

# Vector

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
not familiar with it, is basically a table.  Here we create the data frame and add the 
column name by passing named parameters for each column, such as 'typeof:', 'mode:' and
'storage__mode?'.  You should also note here that the double underscore is converted to a '.'.
So, when printed 'storage\_\_mode' will actually print as 'storage.mode'.

Data frames will later be more carefully described.  In R, the method used to create a 
data frame is 'data.frame', in Galaaz we use 'data\_\_frame'.


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
outputs df.kable.kable_styling
```

<table class="table" style="margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> typeof </th>
   <th style="text-align:left;"> mode </th>
   <th style="text-align:left;"> storage.mode </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> double </td>
   <td style="text-align:left;"> numeric </td>
   <td style="text-align:left;"> double </td>
  </tr>
</tbody>
</table>

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
## /home/rbotafogo/desenv/galaaz/lib/util/exec_ruby.rb:141:in `instance_eval'
## /home/rbotafogo/desenv/galaaz/lib/util/exec_ruby.rb:141:in `exec_ruby'
## /home/rbotafogo/desenv/galaaz/lib/gknit/knitr_engine.rb:650:in `block in initialize'
## /home/rbotafogo/desenv/galaaz/lib/R_interface/ruby_callback.rb:77:in `call'
## /home/rbotafogo/desenv/galaaz/lib/R_interface/ruby_callback.rb:77:in `callback'
## (eval):3:in `function(...) {\n          rb_method(...)'
## unknown.r:1:in `in_dir'
## unknown.r:1:in `block_exec:BLOCK0'
## /home/rbotafogo/lib/graalvm-ce-1.0.0-rc16/jre/languages/R/library/knitr/R/block.R:102:in `block_exec'
## /home/rbotafogo/lib/graalvm-ce-1.0.0-rc16/jre/languages/R/library/knitr/R/block.R:92:in `call_block'
## /home/rbotafogo/lib/graalvm-ce-1.0.0-rc16/jre/languages/R/library/knitr/R/block.R:6:in `process_group.block'
## /home/rbotafogo/lib/graalvm-ce-1.0.0-rc16/jre/languages/R/library/knitr/R/block.R:3:in `<no source>'
## unknown.r:1:in `withCallingHandlers'
## unknown.r:1:in `process_file'
## unknown.r:1:in `<no source>:BLOCK1'
## /home/rbotafogo/lib/graalvm-ce-1.0.0-rc16/jre/languages/R/library/knitr/R/output.R:129:in `<no source>'
## unknown.r:1:in `<no source>:BLOCK1'
## /home/rbotafogo/lib/graalvm-ce-1.0.0-rc16/jre/languages/R/library/rmarkdown/R/render.R:162:in `<no source>'
## <REPL>:5:in `<repl wrapper>'
## <REPL>:1
```

Here is a vector with logical values


```ruby
@vec = R.c(true, true, false, false, true)
puts @vec
```

```
## [1]  TRUE  TRUE FALSE FALSE  TRUE
```

## Combining Vectors

The 'c' functions used to create vectors can also be used to combine two vectors:


```ruby
@vec1 = R.c(10.0, 20.0, 30.0)
@vec2 = R.c(4.0, 5.0, 6.0)
@vec = R.c(@vec1, @vec2)
puts @vec
```

```
## [1] 10 20 30  4  5  6
```
In galaaz, methods can be chainned (somewhat like the pipe operator in R %>%, but more generic).
In this next example, method 'c' is chainned after '@vec1'.  This also looks like 'c' is a 
method of the vector, but in reallity, this is actually closer to the pipe operator.  When
Galaaz identifies that 'c' is not a method of 'vec' it actually tries to call 'R.c' with 
'@vec1' as the first argument concatenated with all the other available arguments.  The code
bellow is automatically converted to the code above.


```ruby
@vec = @vec1.c(@vec2)
puts @vec
```

```
## [1] 10 20 30  4  5  6
```

## Vector Arithmetic

Arithmetic operations on vectors are performed element by element:


```ruby
puts @vec1 + @vec2
```

```
## [1] 14 25 36
```


```ruby
puts @vec1 * 5
```

```
## [1]  50 100 150
```

When vectors have different length, a recycling rule is applied to the shorter vector:


```ruby
@vec3 = R.c(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0)
puts @vec4 = @vec1 + @vec3
```

```
## [1] 11 22 33 14 25 36 17 28 39
```

## Vector Indexing

Vectors can be indexed by using the '[]' operator:


```ruby
puts @vec4[3]
```

```
## [1] 33
```

We can also index a vector with another vector.  For example, in the code bellow, we take elements
1, 3, 5, and 7 from @vec3:


```ruby
puts @vec4[R.c(1, 3, 5, 7)]
```

```
## [1] 11 33 25 17
```

Repeating an index and having indices out of order is valid code:


```ruby
puts @vec4[R.c(1, 3, 3, 1)]
```

```
## [1] 11 33 33 11
```

It is also possible to index a vector with a negative number or negative vector.  In these cases
the indexed values are not returned:


```ruby
puts @vec4[-3]
puts @vec4[-R.c(1, 3, 5, 7)]
```

```
## [1] 11 22 14 25 36 17 28 39
## [1] 22 14 36 28 39
```

If an index is out of range, a missing value (NA) will be reported.


```ruby
puts @vec4[30]
```

```
## [1] NA
```

It is also possible to index a vector by range:


```ruby
puts @vec4[(2..5)]
```

```
## [1] 22 33 14 25
```

Elements in a vector can be named using the 'names' attribute of a vector: 


```ruby
full_name = R.c("Rodrigo", "A", "Botafogo")
full_name.names = R.c("First", "Middle", "Last")
puts full_name
```

```
##      First     Middle       Last 
##  "Rodrigo"        "A" "Botafogo"
```

Or it can also be named by using the 'c' function with named paramenters:


```ruby
full_name = R.c(First: "Rodrigo", Middle: "A", Last: "Botafogo")
puts full_name
```

```
##      First     Middle       Last 
##  "Rodrigo"        "A" "Botafogo"
```

## Extracting Native Ruby Types from a Vector

Vectors created with 'R.c' are of class R::Vector.  You might have noticed that when indexing a
vector, a new vector is returned, even if this vector has one single element. In order to use
R::Vector with other ruby classes it might be necessary to extract the actual Ruby native type
from the vector. In order to do this extraction the '>>' operator is used.


```ruby
puts @vec4
puts @vec4 >> 0
puts @vec4 >> 4
```

```
## [1] 11 22 33 14 25 36 17 28 39
## 11.0
## 25.0
```

Note that indexing with '>>' starts at 0 and not at 1, also, we cannot do negative indexing.

# Accessing R variables

Galaaz allows Ruby to access variables created in R.  For example, the 'mtcars' data set is 
available in R and can be accessed from Ruby by using the 'tilda' operator followed by the
symbol for the variable, in this case ':mtcar'.  In the code bellow method 'outputs' is 
used to output the 'mtcars' data set nicely formatted in HTML by use of the 'kable' and
'kable_styling' functions. Method 'outputs' is only available when used with 'gknit'.


```ruby
outputs (~:mtcars).kable.kable_styling
```

<table class="table" style="margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> mpg </th>
   <th style="text-align:right;"> cyl </th>
   <th style="text-align:right;"> disp </th>
   <th style="text-align:right;"> hp </th>
   <th style="text-align:right;"> drat </th>
   <th style="text-align:right;"> wt </th>
   <th style="text-align:right;"> qsec </th>
   <th style="text-align:right;"> vs </th>
   <th style="text-align:right;"> am </th>
   <th style="text-align:right;"> gear </th>
   <th style="text-align:right;"> carb </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Mazda RX4 </td>
   <td style="text-align:right;"> 21.0 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 160.0 </td>
   <td style="text-align:right;"> 110 </td>
   <td style="text-align:right;"> 3.90 </td>
   <td style="text-align:right;"> 2.620 </td>
   <td style="text-align:right;"> 16.46 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Mazda RX4 Wag </td>
   <td style="text-align:right;"> 21.0 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 160.0 </td>
   <td style="text-align:right;"> 110 </td>
   <td style="text-align:right;"> 3.90 </td>
   <td style="text-align:right;"> 2.875 </td>
   <td style="text-align:right;"> 17.02 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Datsun 710 </td>
   <td style="text-align:right;"> 22.8 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 108.0 </td>
   <td style="text-align:right;"> 93 </td>
   <td style="text-align:right;"> 3.85 </td>
   <td style="text-align:right;"> 2.320 </td>
   <td style="text-align:right;"> 18.61 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Hornet 4 Drive </td>
   <td style="text-align:right;"> 21.4 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 258.0 </td>
   <td style="text-align:right;"> 110 </td>
   <td style="text-align:right;"> 3.08 </td>
   <td style="text-align:right;"> 3.215 </td>
   <td style="text-align:right;"> 19.44 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Hornet Sportabout </td>
   <td style="text-align:right;"> 18.7 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 360.0 </td>
   <td style="text-align:right;"> 175 </td>
   <td style="text-align:right;"> 3.15 </td>
   <td style="text-align:right;"> 3.440 </td>
   <td style="text-align:right;"> 17.02 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Valiant </td>
   <td style="text-align:right;"> 18.1 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 225.0 </td>
   <td style="text-align:right;"> 105 </td>
   <td style="text-align:right;"> 2.76 </td>
   <td style="text-align:right;"> 3.460 </td>
   <td style="text-align:right;"> 20.22 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Duster 360 </td>
   <td style="text-align:right;"> 14.3 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 360.0 </td>
   <td style="text-align:right;"> 245 </td>
   <td style="text-align:right;"> 3.21 </td>
   <td style="text-align:right;"> 3.570 </td>
   <td style="text-align:right;"> 15.84 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Merc 240D </td>
   <td style="text-align:right;"> 24.4 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 146.7 </td>
   <td style="text-align:right;"> 62 </td>
   <td style="text-align:right;"> 3.69 </td>
   <td style="text-align:right;"> 3.190 </td>
   <td style="text-align:right;"> 20.00 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Merc 230 </td>
   <td style="text-align:right;"> 22.8 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 140.8 </td>
   <td style="text-align:right;"> 95 </td>
   <td style="text-align:right;"> 3.92 </td>
   <td style="text-align:right;"> 3.150 </td>
   <td style="text-align:right;"> 22.90 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Merc 280 </td>
   <td style="text-align:right;"> 19.2 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 167.6 </td>
   <td style="text-align:right;"> 123 </td>
   <td style="text-align:right;"> 3.92 </td>
   <td style="text-align:right;"> 3.440 </td>
   <td style="text-align:right;"> 18.30 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Merc 280C </td>
   <td style="text-align:right;"> 17.8 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 167.6 </td>
   <td style="text-align:right;"> 123 </td>
   <td style="text-align:right;"> 3.92 </td>
   <td style="text-align:right;"> 3.440 </td>
   <td style="text-align:right;"> 18.90 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Merc 450SE </td>
   <td style="text-align:right;"> 16.4 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 275.8 </td>
   <td style="text-align:right;"> 180 </td>
   <td style="text-align:right;"> 3.07 </td>
   <td style="text-align:right;"> 4.070 </td>
   <td style="text-align:right;"> 17.40 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Merc 450SL </td>
   <td style="text-align:right;"> 17.3 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 275.8 </td>
   <td style="text-align:right;"> 180 </td>
   <td style="text-align:right;"> 3.07 </td>
   <td style="text-align:right;"> 3.730 </td>
   <td style="text-align:right;"> 17.60 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Merc 450SLC </td>
   <td style="text-align:right;"> 15.2 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 275.8 </td>
   <td style="text-align:right;"> 180 </td>
   <td style="text-align:right;"> 3.07 </td>
   <td style="text-align:right;"> 3.780 </td>
   <td style="text-align:right;"> 18.00 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Cadillac Fleetwood </td>
   <td style="text-align:right;"> 10.4 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 472.0 </td>
   <td style="text-align:right;"> 205 </td>
   <td style="text-align:right;"> 2.93 </td>
   <td style="text-align:right;"> 5.250 </td>
   <td style="text-align:right;"> 17.98 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Lincoln Continental </td>
   <td style="text-align:right;"> 10.4 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 460.0 </td>
   <td style="text-align:right;"> 215 </td>
   <td style="text-align:right;"> 3.00 </td>
   <td style="text-align:right;"> 5.424 </td>
   <td style="text-align:right;"> 17.82 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Chrysler Imperial </td>
   <td style="text-align:right;"> 14.7 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 440.0 </td>
   <td style="text-align:right;"> 230 </td>
   <td style="text-align:right;"> 3.23 </td>
   <td style="text-align:right;"> 5.345 </td>
   <td style="text-align:right;"> 17.42 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Fiat 128 </td>
   <td style="text-align:right;"> 32.4 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 78.7 </td>
   <td style="text-align:right;"> 66 </td>
   <td style="text-align:right;"> 4.08 </td>
   <td style="text-align:right;"> 2.200 </td>
   <td style="text-align:right;"> 19.47 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Honda Civic </td>
   <td style="text-align:right;"> 30.4 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 75.7 </td>
   <td style="text-align:right;"> 52 </td>
   <td style="text-align:right;"> 4.93 </td>
   <td style="text-align:right;"> 1.615 </td>
   <td style="text-align:right;"> 18.52 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Toyota Corolla </td>
   <td style="text-align:right;"> 33.9 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 71.1 </td>
   <td style="text-align:right;"> 65 </td>
   <td style="text-align:right;"> 4.22 </td>
   <td style="text-align:right;"> 1.835 </td>
   <td style="text-align:right;"> 19.90 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Toyota Corona </td>
   <td style="text-align:right;"> 21.5 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 120.1 </td>
   <td style="text-align:right;"> 97 </td>
   <td style="text-align:right;"> 3.70 </td>
   <td style="text-align:right;"> 2.465 </td>
   <td style="text-align:right;"> 20.01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Dodge Challenger </td>
   <td style="text-align:right;"> 15.5 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 318.0 </td>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 2.76 </td>
   <td style="text-align:right;"> 3.520 </td>
   <td style="text-align:right;"> 16.87 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> AMC Javelin </td>
   <td style="text-align:right;"> 15.2 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 304.0 </td>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 3.15 </td>
   <td style="text-align:right;"> 3.435 </td>
   <td style="text-align:right;"> 17.30 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Camaro Z28 </td>
   <td style="text-align:right;"> 13.3 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 350.0 </td>
   <td style="text-align:right;"> 245 </td>
   <td style="text-align:right;"> 3.73 </td>
   <td style="text-align:right;"> 3.840 </td>
   <td style="text-align:right;"> 15.41 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pontiac Firebird </td>
   <td style="text-align:right;"> 19.2 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 400.0 </td>
   <td style="text-align:right;"> 175 </td>
   <td style="text-align:right;"> 3.08 </td>
   <td style="text-align:right;"> 3.845 </td>
   <td style="text-align:right;"> 17.05 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Fiat X1-9 </td>
   <td style="text-align:right;"> 27.3 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 79.0 </td>
   <td style="text-align:right;"> 66 </td>
   <td style="text-align:right;"> 4.08 </td>
   <td style="text-align:right;"> 1.935 </td>
   <td style="text-align:right;"> 18.90 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Porsche 914-2 </td>
   <td style="text-align:right;"> 26.0 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 120.3 </td>
   <td style="text-align:right;"> 91 </td>
   <td style="text-align:right;"> 4.43 </td>
   <td style="text-align:right;"> 2.140 </td>
   <td style="text-align:right;"> 16.70 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Lotus Europa </td>
   <td style="text-align:right;"> 30.4 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 95.1 </td>
   <td style="text-align:right;"> 113 </td>
   <td style="text-align:right;"> 3.77 </td>
   <td style="text-align:right;"> 1.513 </td>
   <td style="text-align:right;"> 16.90 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Ford Pantera L </td>
   <td style="text-align:right;"> 15.8 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 351.0 </td>
   <td style="text-align:right;"> 264 </td>
   <td style="text-align:right;"> 4.22 </td>
   <td style="text-align:right;"> 3.170 </td>
   <td style="text-align:right;"> 14.50 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Ferrari Dino </td>
   <td style="text-align:right;"> 19.7 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 145.0 </td>
   <td style="text-align:right;"> 175 </td>
   <td style="text-align:right;"> 3.62 </td>
   <td style="text-align:right;"> 2.770 </td>
   <td style="text-align:right;"> 15.50 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 6 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Maserati Bora </td>
   <td style="text-align:right;"> 15.0 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 301.0 </td>
   <td style="text-align:right;"> 335 </td>
   <td style="text-align:right;"> 3.54 </td>
   <td style="text-align:right;"> 3.570 </td>
   <td style="text-align:right;"> 14.60 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 8 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Volvo 142E </td>
   <td style="text-align:right;"> 21.4 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 121.0 </td>
   <td style="text-align:right;"> 109 </td>
   <td style="text-align:right;"> 4.11 </td>
   <td style="text-align:right;"> 2.780 </td>
   <td style="text-align:right;"> 18.60 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
</tbody>
</table>

# Matrix

A matrix is a collection of elements organized as a two dimensional table.  A matrix can be 
created by the 'matrix' function:


```ruby
@mat = R.matrix(R.c(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0),
                nrow: 3,
                ncol: 3)

puts @mat
```

```
##      [,1] [,2] [,3]
## [1,]    1    4    7
## [2,]    2    5    8
## [3,]    3    6    9
```
Note that matrices data is organized by column first. It is possible to organize the matrix
memory by row first passing an extra argument to the 'matrix' function:


```ruby
@mat_row = R.matrix(R.c(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0),
                nrow: 3,
                ncol: 3,
                byrow: true)

puts @mat_row
```

```
##      [,1] [,2] [,3]
## [1,]    1    2    3
## [2,]    4    5    6
## [3,]    7    8    9
```

## Indexing a Matrix

A matrix can be indexed by [row, column]:


```ruby
puts @mat_row[1, 1]
puts @mat_row[2, 3]
```

```
## [1] 1
## [1] 6
```
It is possible to index an entire row or column with the ':all' keyword


```ruby
puts @mat_row[1, :all]
puts @mat_row[:all, 2]
```

```
## [1] 1 2 3
## [1] 2 5 8
```

Indexing with a vector is also possible for matrices. In the following example we want
rows 1 and 3 and columns 2 and 3 building a 2 x 2 matrix.


```ruby
puts @mat_row[R.c(1, 3), R.c(2, 3)]
```

```
##      [,1] [,2]
## [1,]    2    3
## [2,]    8    9
```

Matrices can be combined with functions 'rbind' and 'cbind'


```ruby
puts @mat_row.rbind(@mat)
puts @mat_row.cbind(@mat)
```

```
##      [,1] [,2] [,3]
## [1,]    1    2    3
## [2,]    4    5    6
## [3,]    7    8    9
## [4,]    1    4    7
## [5,]    2    5    8
## [6,]    3    6    9
##      [,1] [,2] [,3] [,4] [,5] [,6]
## [1,]    1    2    3    1    4    7
## [2,]    4    5    6    2    5    8
## [3,]    7    8    9    3    6    9
```

# List

A list is a data structure that can contain sublists of different types, while vector and matrix
can only hold one type of element.


```ruby
nums = R.c(1.0, 2.0, 3.0)
strs = R.c("a", "b", "c", "d")
bool = R.c(true, true, false)
@lst = R.list(nums: nums, strs: strs, bool: bool)
puts @lst
```

```
## $nums
## [1] 1 2 3
## 
## $strs
## [1] "a" "b" "c" "d"
## 
## $bool
## [1]  TRUE  TRUE FALSE
```

Note that '@lst' elements are named elements.


## List Indexing

List indexing, also called slicing, is done using the '[]' operator and the '[[]]' operator. Let's
first start with the '[]' operator. The list above has three sublist indexing with '[]' will 
return one of the sublists.


```ruby
puts @lst[1]
```

```
## $nums
## [1] 1 2 3
```

Note that when using '[]' a new list is returned.  When using the double square bracket operator
the value returned is the actual element of the list in the given position and not a slice of
the original list



```ruby
puts @lst[[1]]
```

```
## [1] 1 2 3
```

When elements are named, as dones with @lst, indexing can be done by name:


```ruby
puts @lst[['bool']][[1]] >> 0
```

```
## true
```

In this example, first the 'bool' element of the list was extracted, not as a list, but as a vector,
then the first element of the vector was extracted (note that vectors also accept the '[[]]' 
operator) and then the vector was indexed by its first element, extracting the native Ruby type.


# Data Frame

A data frame is a table like structure in which each column has the same number of 
rows. Data frames are the basic structure for storing data for data analysis.  We have already
seen a data frame previously when we accessed variable '~:mtcars'.  In order to create a
data frame, function 'data__frame' is used:


```ruby
df = R.data__frame(
  year: R.c(2010, 2011, 2012),
  income: R.c(1000.0, 1500.0, 2000.0))

puts df
```

```
##   year income
## 1 2010   1000
## 2 2011   1500
## 3 2012   2000
```

## Data Frame Indexing

A data frame can be indexed the same way as a matrix, by using '[row, column]', where row and
column can either be a numeric or the name of the row or column


```ruby
puts (~:mtcars).head
puts (~:mtcars)[1, 2]
puts (~:mtcars)['Datsun 710', 'mpg']
```

```
##                    mpg cyl disp  hp drat    wt  qsec vs am gear carb
## Mazda RX4         21.0   6  160 110 3.90 2.620 16.46  0  1    4    4
## Mazda RX4 Wag     21.0   6  160 110 3.90 2.875 17.02  0  1    4    4
## Datsun 710        22.8   4  108  93 3.85 2.320 18.61  1  1    4    1
## Hornet 4 Drive    21.4   6  258 110 3.08 3.215 19.44  1  0    3    1
## Hornet Sportabout 18.7   8  360 175 3.15 3.440 17.02  0  0    3    2
## Valiant           18.1   6  225 105 2.76 3.460 20.22  1  0    3    1
## [1] 6
## [1] 22.8
```

Extracting a column from a data frame as a vector can be done by using the double square bracket
operator:


```ruby
puts (~:mtcars)[['mpg']]
```

```
##  [1] 21.0 21.0 22.8 21.4 18.7 18.1 14.3 24.4 22.8 19.2 17.8 16.4 17.3 15.2
## [15] 10.4 10.4 14.7 32.4 30.4 33.9 21.5 15.5 15.2 13.3 19.2 27.3 26.0 30.4
## [29] 15.8 19.7 15.0 21.4
```

A data frame column can also be accessed as if it were an instance variable of the data frame:


```ruby
puts (~:mtcars).mpg
```

```
##  [1] 21.0 21.0 22.8 21.4 18.7 18.1 14.3 24.4 22.8 19.2 17.8 16.4 17.3 15.2
## [15] 10.4 10.4 14.7 32.4 30.4 33.9 21.5 15.5 15.2 13.3 19.2 27.3 26.0 30.4
## [29] 15.8 19.7 15.0 21.4
```

Slicing a data frame can be done by indexing it with a vector (we use 'head' to reduce the
output):


```ruby
puts (~:mtcars)[R.c('mpg', 'hp')].head
```

```
##                    mpg  hp
## Mazda RX4         21.0 110
## Mazda RX4 Wag     21.0 110
## Datsun 710        22.8  93
## Hornet 4 Drive    21.4 110
## Hornet Sportabout 18.7 175
## Valiant           18.1 105
```

A row slice can be obtained by indexing by row and using the ':all' keyword for the column:


```ruby
puts (~:mtcars)[R.c('Datsun 710', 'Camaro Z28'), :all]
```

```
##             mpg cyl disp  hp drat   wt  qsec vs am gear carb
## Datsun 710 22.8   4  108  93 3.85 2.32 18.61  1  1    4    1
## Camaro Z28 13.3   8  350 245 3.73 3.84 15.41  0  0    3    4
```

Finally, a data frame can also be indexed with a logical vector.  In this next example, the
'am' column of :mtcars is compared with 0 (with method 'eq').  When 'am' is equal to 0 the
car is automatic.  So, by doing '(~:mtcars).am.eq 0' a logical vector is created with 
'true' whenever 'am' is 0 and 'false' otherwise.  Using this logical vector, the data frame
is indexed, returning a new data frame in which all cars have automatic transmission.


```ruby
# obtain a vector with 'true' for cars with automatic transmission
automatic = (~:mtcars).am.eq 0
puts automatic

# slice the data frame by using this vector
puts (~:mtcars)[automatic, :all]
```

```
##  [1] FALSE FALSE FALSE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE
## [12]  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE FALSE FALSE FALSE  TRUE  TRUE
## [23]  TRUE  TRUE  TRUE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
##                      mpg cyl  disp  hp drat    wt  qsec vs am gear carb
## Hornet 4 Drive      21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
## Hornet Sportabout   18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
## Valiant             18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
## Duster 360          14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
## Merc 240D           24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
## Merc 230            22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
## Merc 280            19.2   6 167.6 123 3.92 3.440 18.30  1  0    4    4
## Merc 280C           17.8   6 167.6 123 3.92 3.440 18.90  1  0    4    4
## Merc 450SE          16.4   8 275.8 180 3.07 4.070 17.40  0  0    3    3
## Merc 450SL          17.3   8 275.8 180 3.07 3.730 17.60  0  0    3    3
## Merc 450SLC         15.2   8 275.8 180 3.07 3.780 18.00  0  0    3    3
## Cadillac Fleetwood  10.4   8 472.0 205 2.93 5.250 17.98  0  0    3    4
## Lincoln Continental 10.4   8 460.0 215 3.00 5.424 17.82  0  0    3    4
## Chrysler Imperial   14.7   8 440.0 230 3.23 5.345 17.42  0  0    3    4
## Toyota Corona       21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
## Dodge Challenger    15.5   8 318.0 150 2.76 3.520 16.87  0  0    3    2
## AMC Javelin         15.2   8 304.0 150 3.15 3.435 17.30  0  0    3    2
## Camaro Z28          13.3   8 350.0 245 3.73 3.840 15.41  0  0    3    4
## Pontiac Firebird    19.2   8 400.0 175 3.08 3.845 17.05  0  0    3    2
```

# Writing Expressions in Galaaz

Galaaz extends Ruby to work with complex expressions, similar to R's expressions build with 'quote' 
(base R) or 'quo' (tidyverse).  Let's take a look at some of those expressions.

## Expressions from operators

The code bellow 
creates an expression summing two symbols


```ruby
exp1 = :a + :b
puts exp1
```

```
## a + b
```
We can build any complex mathematical expression


```ruby
exp2 = (:a + :b) * 2.0 + :c ** 2 / :z
puts exp2
```

```
## (a + b) * 2 + c^2L/z
```

It is also possible to use inequality operators in building expressions


```ruby
exp3 = (:a + :b) >= :z
puts exp3
```

```
## a + b >= z
```

Galaaz provides both symbolic representations for operators, such as (>, <, !=) as functional 
notation for those operators such as (.gt, .ge, etc.).  So the same expression written 
above can also be written as


```ruby
exp4 = (:a + :b).ge :z
puts exp4
```

```
## a + b >= z
```

Two type of expression can only be created with the functional representation of the operators, 
those are expressions involving '==', and '='.  In order to write an expression involving '==' we
need to use the method '.eq' and for '=' we need the function '.assign'


```ruby
exp5 = (:a + :b).eq :z
puts exp5
```

```
## a + b == z
```


```ruby
exp6 = :y.assign :a + :b
puts exp6
```

```
## y <- a + b
```
In general we think that using the functional notation is preferable to using the 
symbolic notation as otherwise, we end up writing invalid expressions such as


```ruby
exp_wrong = (:a + :b) == :z
puts exp_wrong
```

```
## Message:
##  Error in function (x, y, num.eq = TRUE, single.NA = TRUE, attrib.as.set = TRUE,  :
##   object 'a' not found (RError)
## Translated to internal error
```
and it might be difficult to understand what is going on here.  The problem lies with the fact that
when using '==' we are comparing expression (:a + :b) to expression :z with '=='.  When the 
comparison is executed, the system tries to evaluate :a, :b and :z, and those symbols at 
this time are not bound to anything and we get a "object 'a' not found" message.
If we only use functional notation, this type of error will not occur.

## Expressions with R methods

It is often necessary to create an expression that uses a method or function.  For instance, in
mathematics, it's quite natural to write an expressin such as $y = sin(x)$. In this case, the
'sin' function is part of the expression and should not immediately executed. Now, let's say
that 'x' is an angle of 45$^\circ$ and we acttually want our expression to be $y = 0.850...$.
When we want the function to be part of the expression, we call the function preceeding it
by the letter E, such as 'E.sin(x)'


```ruby
exp7 = :y.assign E.sin(:x)
puts exp7
```

```
## y <- sin(x)
```

# Manipulating Data

One of the major benefits of Galaaz is to bring strong data manipulation to Ruby. The following
examples were extracted from Hardley's "R for Data Science" (https://r4ds.had.co.nz/). This
is a highly recommended book for those not already familiar with the 'tidyverse' style of
programming in R. In the sections to follow, we will limit ourselves to convert the R code to
Galaaz. 

For these
examples, we will investigate the nycflights13 data set available on the package by the
same name.  We use function 'R.install_and_loads' that checks if the library is available 
locally, and if not, installs it. This data frame contains all 336,776 flights that 
departed from New York City in 2013. The data comes from the US Bureau of 
Transportation Statistics.


```ruby
R.install_and_loads('nycflights13')
R.library('dplyr')
```


```ruby
@flights = ~:flights
puts @flights.head.as__data__frame
```

```
##   year month day dep_time sched_dep_time dep_delay arr_time sched_arr_time
## 1 2013     1   1      517            515         2      830            819
## 2 2013     1   1      533            529         4      850            830
## 3 2013     1   1      542            540         2      923            850
## 4 2013     1   1      544            545        -1     1004           1022
## 5 2013     1   1      554            600        -6      812            837
## 6 2013     1   1      554            558        -4      740            728
##   arr_delay carrier flight tailnum origin dest air_time distance hour
## 1        11      UA   1545  N14228    EWR  IAH      227     1400    5
## 2        20      UA   1714  N24211    LGA  IAH      227     1416    5
## 3        33      AA   1141  N619AA    JFK  MIA      160     1089    5
## 4       -18      B6    725  N804JB    JFK  BQN      183     1576    5
## 5       -25      DL    461  N668DN    LGA  ATL      116      762    6
## 6        12      UA   1696  N39463    EWR  ORD      150      719    5
##   minute           time_hour
## 1     15 2013-01-01 05:00:00
## 2     29 2013-01-01 05:00:00
## 3     40 2013-01-01 05:00:00
## 4     45 2013-01-01 05:00:00
## 5      0 2013-01-01 06:00:00
## 6     58 2013-01-01 05:00:00
```

## Filtering rows with Filter

In this example we filter the flights data set by giving to the filter function two expressions:
the first :month.eq 1


```ruby
puts @flights.filter((:month.eq 1), (:day.eq 1)).head.as__data__frame
```

```
##   year month day dep_time sched_dep_time dep_delay arr_time sched_arr_time
## 1 2013     1   1      517            515         2      830            819
## 2 2013     1   1      533            529         4      850            830
## 3 2013     1   1      542            540         2      923            850
## 4 2013     1   1      544            545        -1     1004           1022
## 5 2013     1   1      554            600        -6      812            837
## 6 2013     1   1      554            558        -4      740            728
##   arr_delay carrier flight tailnum origin dest air_time distance hour
## 1        11      UA   1545  N14228    EWR  IAH      227     1400    5
## 2        20      UA   1714  N24211    LGA  IAH      227     1416    5
## 3        33      AA   1141  N619AA    JFK  MIA      160     1089    5
## 4       -18      B6    725  N804JB    JFK  BQN      183     1576    5
## 5       -25      DL    461  N668DN    LGA  ATL      116      762    6
## 6        12      UA   1696  N39463    EWR  ORD      150      719    5
##   minute           time_hour
## 1     15 2013-01-01 05:00:00
## 2     29 2013-01-01 05:00:00
## 3     40 2013-01-01 05:00:00
## 4     45 2013-01-01 05:00:00
## 5      0 2013-01-01 06:00:00
## 6     58 2013-01-01 05:00:00
```

## Logical Operators

All flights that departed in November of December


```ruby
puts @flights.filter((:month.eq 11) | (:month.eq 12)).head.as__data__frame
```

```
##   year month day dep_time sched_dep_time dep_delay arr_time sched_arr_time
## 1 2013    11   1        5           2359         6      352            345
## 2 2013    11   1       35           2250       105      123           2356
## 3 2013    11   1      455            500        -5      641            651
## 4 2013    11   1      539            545        -6      856            827
## 5 2013    11   1      542            545        -3      831            855
## 6 2013    11   1      549            600       -11      912            923
##   arr_delay carrier flight tailnum origin dest air_time distance hour
## 1         7      B6    745  N568JB    JFK  PSE      205     1617   23
## 2        87      B6   1816  N353JB    JFK  SYR       36      209   22
## 3       -10      US   1895  N192UW    EWR  CLT       88      529    5
## 4        29      UA   1714  N38727    LGA  IAH      229     1416    5
## 5       -24      AA   2243  N5CLAA    JFK  MIA      147     1089    5
## 6       -11      UA    303  N595UA    JFK  SFO      359     2586    6
##   minute           time_hour
## 1     59 2013-11-01 23:00:00
## 2     50 2013-11-01 22:00:00
## 3      0 2013-11-01 05:00:00
## 4     45 2013-11-01 05:00:00
## 5     45 2013-11-01 05:00:00
## 6      0 2013-11-01 06:00:00
```

The same as above, but using the 'in' operator. In R, it is possible to define many operators
by doing %<op>%. The %in% operator checks if a value is in a vector.  In order to use those
operators from Galaaz the '._' method is used, where the first argument is the operator's
symbol, in this case ':in' and the second argument is the vector:


```ruby
puts @flights.filter(:month._ :in, R.c(11, 12)).head.as__data__frame
```

```
##   year month day dep_time sched_dep_time dep_delay arr_time sched_arr_time
## 1 2013    11   1        5           2359         6      352            345
## 2 2013    11   1       35           2250       105      123           2356
## 3 2013    11   1      455            500        -5      641            651
## 4 2013    11   1      539            545        -6      856            827
## 5 2013    11   1      542            545        -3      831            855
## 6 2013    11   1      549            600       -11      912            923
##   arr_delay carrier flight tailnum origin dest air_time distance hour
## 1         7      B6    745  N568JB    JFK  PSE      205     1617   23
## 2        87      B6   1816  N353JB    JFK  SYR       36      209   22
## 3       -10      US   1895  N192UW    EWR  CLT       88      529    5
## 4        29      UA   1714  N38727    LGA  IAH      229     1416    5
## 5       -24      AA   2243  N5CLAA    JFK  MIA      147     1089    5
## 6       -11      UA    303  N595UA    JFK  SFO      359     2586    6
##   minute           time_hour
## 1     59 2013-11-01 23:00:00
## 2     50 2013-11-01 22:00:00
## 3      0 2013-11-01 05:00:00
## 4     45 2013-11-01 05:00:00
## 5     45 2013-11-01 05:00:00
## 6      0 2013-11-01 06:00:00
```

## Filtering with NA (Not Available)

Let's first create a 'tibble' with a Not Available value (R::NA).  Tibbles are a modern 
version of a data frame and operate very similarly to one.  It differs in how it outputs
the values and the result of some subsetting operations that are more consistent than
what is obtained from data frame.


```ruby
@df = R.tibble(x: R.c(1, R::NA, 3))
puts @df.as__data__frame
```

```
##    x
## 1  1
## 2 NA
## 3  3
```

Now filtering by :x > 1 shows all lines that satisfy this condition, where the row with R:NA does
not.


```ruby
puts @df.filter(:x > 1).as__data__frame
```

```
##   x
## 1 3
```

To match an NA use method 'is__na'


```ruby
puts @df.filter((:x.is__na) | (:x > 1)).as__data__frame
```

```
##    x
## 1 NA
## 2  3
```

## Arrange Rows with arrange

Arrange reorders the rows of a data frame by the given arguments.


```ruby
puts @flights.arrange(:year, :month, :day).head.as__data__frame
```

```
##   year month day dep_time sched_dep_time dep_delay arr_time sched_arr_time
## 1 2013     1   1      517            515         2      830            819
## 2 2013     1   1      533            529         4      850            830
## 3 2013     1   1      542            540         2      923            850
## 4 2013     1   1      544            545        -1     1004           1022
## 5 2013     1   1      554            600        -6      812            837
## 6 2013     1   1      554            558        -4      740            728
##   arr_delay carrier flight tailnum origin dest air_time distance hour
## 1        11      UA   1545  N14228    EWR  IAH      227     1400    5
## 2        20      UA   1714  N24211    LGA  IAH      227     1416    5
## 3        33      AA   1141  N619AA    JFK  MIA      160     1089    5
## 4       -18      B6    725  N804JB    JFK  BQN      183     1576    5
## 5       -25      DL    461  N668DN    LGA  ATL      116      762    6
## 6        12      UA   1696  N39463    EWR  ORD      150      719    5
##   minute           time_hour
## 1     15 2013-01-01 05:00:00
## 2     29 2013-01-01 05:00:00
## 3     40 2013-01-01 05:00:00
## 4     45 2013-01-01 05:00:00
## 5      0 2013-01-01 06:00:00
## 6     58 2013-01-01 05:00:00
```

To arrange in descending order, use function 'desc'


```ruby
puts @flights.arrange(:dep_delay.desc).head.as__data__frame
```

```
##   year month day dep_time sched_dep_time dep_delay arr_time sched_arr_time
## 1 2013     1   9      641            900      1301     1242           1530
## 2 2013     6  15     1432           1935      1137     1607           2120
## 3 2013     1  10     1121           1635      1126     1239           1810
## 4 2013     9  20     1139           1845      1014     1457           2210
## 5 2013     7  22      845           1600      1005     1044           1815
## 6 2013     4  10     1100           1900       960     1342           2211
##   arr_delay carrier flight tailnum origin dest air_time distance hour
## 1      1272      HA     51  N384HA    JFK  HNL      640     4983    9
## 2      1127      MQ   3535  N504MQ    JFK  CMH       74      483   19
## 3      1109      MQ   3695  N517MQ    EWR  ORD      111      719   16
## 4      1007      AA    177  N338AA    JFK  SFO      354     2586   18
## 5       989      MQ   3075  N665MQ    JFK  CVG       96      589   16
## 6       931      DL   2391  N959DL    JFK  TPA      139     1005   19
##   minute           time_hour
## 1      0 2013-01-09 09:00:00
## 2     35 2013-06-15 19:00:00
## 3     35 2013-01-10 16:00:00
## 4     45 2013-09-20 18:00:00
## 5      0 2013-07-22 16:00:00
## 6      0 2013-04-10 19:00:00
```

## Selecting columns

To select specific columns from a dataset we use function 'select':


```ruby
puts @flights.select(:year, :month, :day).head.as__data__frame
```

```
##   year month day
## 1 2013     1   1
## 2 2013     1   1
## 3 2013     1   1
## 4 2013     1   1
## 5 2013     1   1
## 6 2013     1   1
```

It is also possible to select column in a given range


```ruby
puts @flights.select(:year.up_to :day).head.as__data__frame
```

```
##   year month day
## 1 2013     1   1
## 2 2013     1   1
## 3 2013     1   1
## 4 2013     1   1
## 5 2013     1   1
## 6 2013     1   1
```

Select all columns that start with a given name sequence


```ruby
puts @flights.select(E.starts_with('arr')).head.as__data__frame
```

```
##   arr_time arr_delay
## 1      830        11
## 2      850        20
## 3      923        33
## 4     1004       -18
## 5      812       -25
## 6      740        12
```

Other functions that can be used:

* ends_with("xyz"): matches names that end with “xyz”.

* contains("ijk"): matches names that contain “ijk”.

* matches("(.)\\1"): selects variables that match a regular expression. This one matches 
  any variables that contain repeated characters.
  
* num_range("x", (1..3)): matches x1, x2 and x3

A helper function that comes in handy when we just want to rearrange column order is 'Everything':


```ruby
puts @flights.select(:year, :month, :day, E.everything).head.as__data__frame
```

```
##   year month day dep_time sched_dep_time dep_delay arr_time sched_arr_time
## 1 2013     1   1      517            515         2      830            819
## 2 2013     1   1      533            529         4      850            830
## 3 2013     1   1      542            540         2      923            850
## 4 2013     1   1      544            545        -1     1004           1022
## 5 2013     1   1      554            600        -6      812            837
## 6 2013     1   1      554            558        -4      740            728
##   arr_delay carrier flight tailnum origin dest air_time distance hour
## 1        11      UA   1545  N14228    EWR  IAH      227     1400    5
## 2        20      UA   1714  N24211    LGA  IAH      227     1416    5
## 3        33      AA   1141  N619AA    JFK  MIA      160     1089    5
## 4       -18      B6    725  N804JB    JFK  BQN      183     1576    5
## 5       -25      DL    461  N668DN    LGA  ATL      116      762    6
## 6        12      UA   1696  N39463    EWR  ORD      150      719    5
##   minute           time_hour
## 1     15 2013-01-01 05:00:00
## 2     29 2013-01-01 05:00:00
## 3     40 2013-01-01 05:00:00
## 4     45 2013-01-01 05:00:00
## 5      0 2013-01-01 06:00:00
## 6     58 2013-01-01 05:00:00
```

## Add variables to a dataframe with 'mutate'


```ruby
@flights_sm = @flights.
                select((:year.up_to :day),
                       E.ends_with('delay'),
                       :distance,
                       :air_time)

puts @flights_sm.head.as__data__frame
```

```
##   year month day dep_delay arr_delay distance air_time
## 1 2013     1   1         2        11     1400      227
## 2 2013     1   1         4        20     1416      227
## 3 2013     1   1         2        33     1089      160
## 4 2013     1   1        -1       -18     1576      183
## 5 2013     1   1        -6       -25      762      116
## 6 2013     1   1        -4        12      719      150
```


```ruby
@flights_sm = @flights_sm.
                mutate(gain: :dep_delay - :arr_delay,
                       speed: :distance / :air_time * 60)
puts @flights_sm.head.as__data__frame
```

```
##   year month day dep_delay arr_delay distance air_time gain    speed
## 1 2013     1   1         2        11     1400      227   -9 370.0441
## 2 2013     1   1         4        20     1416      227  -16 374.2731
## 3 2013     1   1         2        33     1089      160  -31 408.3750
## 4 2013     1   1        -1       -18     1576      183   17 516.7213
## 5 2013     1   1        -6       -25      762      116   19 394.1379
## 6 2013     1   1        -4        12      719      150  -16 287.6000
```

## Summarising data

Function 'summarise' calculates summaries for the data frame. When no 'group_by' is used
a single value is obtained from the data frame:


```ruby
puts @flights.summarise(delay: E.mean(:dep_delay, na__rm: true)).as__data__frame
```

```
##      delay
## 1 12.63907
```

When a data frame is groupe with 'group_by' summaries apply to the given group:


```ruby
by_day = @flights.group_by(:year, :month, :day)
puts by_day.summarise(delay: :dep_delay.mean(na__rm: true)).head.as__data__frame
```

```
##   year month day     delay
## 1 2013     1   1 11.548926
## 2 2013     1   2 13.858824
## 3 2013     1   3 10.987832
## 4 2013     1   4  8.951595
## 5 2013     1   5  5.732218
## 6 2013     1   6  7.148014
```

Next we put many operations together by pipping them one after the other:


```ruby
delays = @flights.
           group_by(:dest).
           summarise(
             count: E.n,
             dist: :distance.mean(na__rm: true),
             delay: :arr_delay.mean(na__rm: true)).
           filter(:count > 20, :dest != "NHL")

puts delays.as__data__frame
```

```
##    dest count       dist       delay
## 1   ABQ   254 1826.00000  4.38188976
## 2   ACK   265  199.00000  4.85227273
## 3   ALB   439  143.00000 14.39712919
## 4   ATL 17215  757.10822 11.30011285
## 5   AUS  2439 1514.25297  6.01990875
## 6   AVL   275  583.58182  8.00383142
## 7   BDL   443  116.00000  7.04854369
## 8   BGR   375  378.00000  8.02793296
## 9   BHM   297  865.99663 16.87732342
## 10  BNA  6333  758.21348 11.81245891
## 11  BOS 15508  190.63696  2.91439222
## 12  BQN   896 1578.98326  8.24549550
## 13  BTV  2589  265.09154  8.95099602
## 14  BUF  4681  296.80837  8.94595186
## 15  BUR   371 2465.00000  8.17567568
## 16  BWI  1781  179.41830 10.72673385
## 17  BZN    36 1882.00000  7.60000000
## 18  CAE   116  603.55172 41.76415094
## 19  CAK   864  397.00000 19.69833729
## 20  CHO    52  305.00000  9.50000000
## 21  CHS  2884  632.91678 10.59296847
## 22  CLE  4573  414.17428  9.18161129
## 23  CLT 14064  538.02730  7.36031885
## 24  CMH  3524  476.55505 10.60132291
## 25  CRW   138  444.00000 14.67164179
## 26  CVG  3941  575.15986 15.36456376
## 27  DAY  1525  537.10230 12.68048606
## 28  DCA  9705  211.00618  9.06695204
## 29  DEN  7266 1614.67836  8.60650021
## 30  DFW  8738 1383.04303  0.32212685
## 31  DSM   569 1020.88752 19.00573614
## 32  DTW  9384  498.12852  5.42996346
## 33  EGE   213 1735.70892  6.30434783
## 34  FLL 12055 1070.06877  8.08212154
## 35  GRR   765  605.78170 18.18956044
## 36  GSO  1606  449.84184 14.11260054
## 37  GSP   849  595.95995 15.93544304
## 38  HNL   707 4972.67468 -1.36519258
## 39  HOU  2115 1420.15508  7.17618819
## 40  IAD  5700  224.84684 13.86420212
## 41  IAH  7198 1407.20672  4.24079040
## 42  ILM   110  500.00000  4.63551402
## 43  IND  2077  652.26288  9.94043412
## 44  JAC    25 1875.60000 28.09523810
## 45  JAX  2720  824.67610 11.84483416
## 46  LAS  5997 2240.96148  0.25772849
## 47  LAX 16174 2468.62236  0.54711094
## 48  LGB   668 2465.00000 -0.06202723
## 49  MCI  2008 1097.69522 14.51405836
## 50  MCO 14082  943.11057  5.45464309
## 51  MDW  4113  718.04595 12.36422360
## 52  MEM  1789  954.20123 10.64531435
## 53  MHT  1009  207.02973 14.78755365
## 54  MIA 11728 1091.55244  0.29905978
## 55  MKE  2802  733.38151 14.16722038
## 56  MSN   572  803.95455 20.19604317
## 57  MSP  7185 1017.40167  7.27016886
## 58  MSY  3799 1177.70571  6.49017497
## 59  MVY   221  173.00000 -0.28571429
## 60  MYR    59  550.66102  4.60344828
## 61  OAK   312 2576.00000  3.07766990
## 62  OKC   346 1325.00000 30.61904762
## 63  OMA   849 1135.56655 14.69889841
## 64  ORD 17283  729.00081  5.87661475
## 65  ORF  1536  288.52344 10.94909344
## 66  PBI  6554 1028.83811  8.56297210
## 67  PDX  1354 2445.56573  5.14157973
## 68  PHL  1632   94.32353 10.12719014
## 69  PHX  4656 2141.30326  2.09704733
## 70  PIT  2875  334.06122  7.68099053
## 71  PSE   365 1617.00000  7.87150838
## 72  PVD   376  160.00000 16.23463687
## 73  PWM  2352  276.12840 11.66040210
## 74  RDU  8163  426.75769 10.05238095
## 75  RIC  2454  281.40465 20.11125320
## 76  ROC  2416  259.25083 11.56064461
## 77  RSW  3537 1072.85327  3.23814963
## 78  SAN  2737 2437.29923  3.13916574
## 79  SAT   686 1578.34111  6.94537178
## 80  SAV   804  709.18408 15.12950601
## 81  SDF  1157  645.98358 12.66938406
## 82  SEA  3923 2412.66531 -1.09909910
## 83  SFO 13331 2577.92356  2.67289152
## 84  SJC   329 2569.00000  3.44817073
## 85  SJU  5819 1599.83365  2.52052659
## 86  SLC  2467 1986.98662  0.17625459
## 87  SMF   284 2521.00000 12.10992908
## 88  SNA   825 2434.00000 -7.86822660
## 89  SRQ  1211 1044.65153  3.08243131
## 90  STL  4339  878.72321 11.07846451
## 91  STT   522 1626.98276 -3.83590734
## 92  SYR  1761  205.92164  8.90392501
## 93  TPA  7466 1003.93557  7.40852503
## 94  TUL   315 1215.00000 33.65986395
## 95  TVC   101  652.38614 12.96842105
## 96  TYS   631  638.80983 24.06920415
## 97  XNA  1036 1142.50579  7.46572581
```

# Using Data Table


```ruby
R.library('data.table')
R.install_and_loads('curl')

input = "https://raw.githubusercontent.com/Rdatatable/data.table/master/vignettes/flights14.csv"
@flights = R.fread(input)
puts @flights
puts @flights.dim
```

```
##         year month day dep_delay arr_delay carrier origin dest air_time
##      1: 2014     1   1        14        13      AA    JFK  LAX      359
##      2: 2014     1   1        -3        13      AA    JFK  LAX      363
##      3: 2014     1   1         2         9      AA    JFK  LAX      351
##      4: 2014     1   1        -8       -26      AA    LGA  PBI      157
##      5: 2014     1   1         2         1      AA    JFK  LAX      350
##     ---                                                                
## 253312: 2014    10  31         1       -30      UA    LGA  IAH      201
## 253313: 2014    10  31        -5       -14      UA    EWR  IAH      189
## 253314: 2014    10  31        -8        16      MQ    LGA  RDU       83
## 253315: 2014    10  31        -4        15      MQ    LGA  DTW       75
## 253316: 2014    10  31        -5         1      MQ    LGA  SDF      110
##         distance hour
##      1:     2475    9
##      2:     2475   11
##      3:     2475   19
##      4:     1035    7
##      5:     2475   13
##     ---              
## 253312:     1416   14
## 253313:     1400    8
## 253314:      431   11
## 253315:      502   11
## 253316:      659    8
## [1] 253316     11
```


```ruby

data_table = R.data__table(
  ID: R.c("b","b","b","a","a","c"),
  a: (1..6),
  b: (7..12),
  c: (13..18)
)

puts data_table
puts data_table.ID
```

```
##    ID a  b  c
## 1:  b 1  7 13
## 2:  b 2  8 14
## 3:  b 3  9 15
## 4:  a 4 10 16
## 5:  a 5 11 17
## 6:  c 6 12 18
## [1] "b" "b" "b" "a" "a" "c"
```


```ruby
# subset rows in i
ans = @flights[(:origin.eq "JFK") & (:month.eq 6)]
puts ans.head

# Get the first two rows from flights.

ans = @flights[(1..2)]
puts ans

# Sort flights first by column origin in ascending order, and then by dest in descending order:

# ans = @flights[E.order(:origin, -(:dest))]
# puts ans.head
```

```
##    year month day dep_delay arr_delay carrier origin dest air_time
## 1: 2014     6   1        -9        -5      AA    JFK  LAX      324
## 2: 2014     6   1       -10       -13      AA    JFK  LAX      329
## 3: 2014     6   1        18        -1      AA    JFK  LAX      326
## 4: 2014     6   1        -6       -16      AA    JFK  LAX      320
## 5: 2014     6   1        -4       -45      AA    JFK  LAX      326
## 6: 2014     6   1        -6       -23      AA    JFK  LAX      329
##    distance hour
## 1:     2475    8
## 2:     2475   12
## 3:     2475    7
## 4:     2475   10
## 5:     2475   18
## 6:     2475   14
##    year month day dep_delay arr_delay carrier origin dest air_time
## 1: 2014     1   1        14        13      AA    JFK  LAX      359
## 2: 2014     1   1        -3        13      AA    JFK  LAX      363
##    distance hour
## 1:     2475    9
## 2:     2475   11
```


```ruby
# Select column(s) in j
# select arr_delay column, but return it as a vector.

ans = @flights[:all, :arr_delay]
puts ans.head

# Select arr_delay column, but return as a data.table instead.

ans = @flights[:all, :arr_delay.list]
puts ans.head

ans = @flights[:all, E.list(:arr_delay, :dep_delay)]
```

```
## [1]  13  13   9 -26   1   0
##    arr_delay
## 1:        13
## 2:        13
## 3:         9
## 4:       -26
## 5:         1
## 6:         0
```

# Graphics in Galaaz

Creating graphics in Galaaz is quite easy, as it can use all the power of ggplot2.  There are
many resources in the web that teaches ggplot, so here we give a quick example of ggplot 
integration with Ruby.  We continue to use the :mtcars dataset and we will plot a diverging
bar plot, showing cars that have 'above' or 'below' gas consuption. Let's first prepare
the data frame with the necessary data:


```ruby
# copy the R variable :mtcars to the Ruby mtcars variable
@mtcars = ~:mtcars

# create a new column 'car_name' to store the car names so that it can be
# used for plotting. The 'rownames' of the data frame cannot be used as
# data for plotting
@mtcars.car_name = R.rownames(:mtcars)

# compute normalized mpg and add it to a new column called mpg_z
# Note that the mean value for mpg can be obtained by calling the 'mean'
# function on the vector 'mtcars.mpg'.  The same with the standard
# deviation 'sd'.  The vector is then rounded to two digits with 'round 2'
@mtcars.mpg_z = ((@mtcars.mpg - @mtcars.mpg.mean)/@mtcars.mpg.sd).round 2

# create a new column 'mpg_type'. Function 'ifelse' is a vectorized function
# that looks at every element of the mpg_z vector and if the value is below
# 0, returns 'below', otherwise returns 'above'
@mtcars.mpg_type = (@mtcars.mpg_z < 0).ifelse("below", "above")

# order the mtcar data set by the mpg_z vector from smaler to larger values
@mtcars = @mtcars[@mtcars.mpg_z.order, :all]

# convert the car_name column to a factor to retain sorted order in plot
@mtcars.car_name = @mtcars.car_name.factor levels: @mtcars.car_name

# let's look at the final data frame
puts @mtcars
```

```
##                      mpg cyl  disp  hp drat    wt  qsec vs am gear carb
## Cadillac Fleetwood  10.4   8 472.0 205 2.93 5.250 17.98  0  0    3    4
## Lincoln Continental 10.4   8 460.0 215 3.00 5.424 17.82  0  0    3    4
## Camaro Z28          13.3   8 350.0 245 3.73 3.840 15.41  0  0    3    4
## Duster 360          14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
## Chrysler Imperial   14.7   8 440.0 230 3.23 5.345 17.42  0  0    3    4
## Maserati Bora       15.0   8 301.0 335 3.54 3.570 14.60  0  1    5    8
## Merc 450SLC         15.2   8 275.8 180 3.07 3.780 18.00  0  0    3    3
## AMC Javelin         15.2   8 304.0 150 3.15 3.435 17.30  0  0    3    2
## Dodge Challenger    15.5   8 318.0 150 2.76 3.520 16.87  0  0    3    2
## Ford Pantera L      15.8   8 351.0 264 4.22 3.170 14.50  0  1    5    4
## Merc 450SE          16.4   8 275.8 180 3.07 4.070 17.40  0  0    3    3
## Merc 450SL          17.3   8 275.8 180 3.07 3.730 17.60  0  0    3    3
## Merc 280C           17.8   6 167.6 123 3.92 3.440 18.90  1  0    4    4
## Valiant             18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
## Hornet Sportabout   18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
## Merc 280            19.2   6 167.6 123 3.92 3.440 18.30  1  0    4    4
## Pontiac Firebird    19.2   8 400.0 175 3.08 3.845 17.05  0  0    3    2
## Ferrari Dino        19.7   6 145.0 175 3.62 2.770 15.50  0  1    5    6
## Mazda RX4           21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4
## Mazda RX4 Wag       21.0   6 160.0 110 3.90 2.875 17.02  0  1    4    4
## Hornet 4 Drive      21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
## Volvo 142E          21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2
## Toyota Corona       21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
## Datsun 710          22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
## Merc 230            22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
## Merc 240D           24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
## Porsche 914-2       26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
## Fiat X1-9           27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
## Honda Civic         30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
## Lotus Europa        30.4   4  95.1 113 3.77 1.513 16.90  1  1    5    2
## Fiat 128            32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
## Toyota Corolla      33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
##                                car_name mpg_z mpg_type
## Cadillac Fleetwood   Cadillac Fleetwood -1.61    below
## Lincoln Continental Lincoln Continental -1.61    below
## Camaro Z28                   Camaro Z28 -1.13    below
## Duster 360                   Duster 360 -0.96    below
## Chrysler Imperial     Chrysler Imperial -0.89    below
## Maserati Bora             Maserati Bora -0.84    below
## Merc 450SLC                 Merc 450SLC -0.81    below
## AMC Javelin                 AMC Javelin -0.81    below
## Dodge Challenger       Dodge Challenger -0.76    below
## Ford Pantera L           Ford Pantera L -0.71    below
## Merc 450SE                   Merc 450SE -0.61    below
## Merc 450SL                   Merc 450SL -0.46    below
## Merc 280C                     Merc 280C -0.38    below
## Valiant                         Valiant -0.33    below
## Hornet Sportabout     Hornet Sportabout -0.23    below
## Merc 280                       Merc 280 -0.15    below
## Pontiac Firebird       Pontiac Firebird -0.15    below
## Ferrari Dino               Ferrari Dino -0.06    below
## Mazda RX4                     Mazda RX4  0.15    above
## Mazda RX4 Wag             Mazda RX4 Wag  0.15    above
## Hornet 4 Drive           Hornet 4 Drive  0.22    above
## Volvo 142E                   Volvo 142E  0.22    above
## Toyota Corona             Toyota Corona  0.23    above
## Datsun 710                   Datsun 710  0.45    above
## Merc 230                       Merc 230  0.45    above
## Merc 240D                     Merc 240D  0.72    above
## Porsche 914-2             Porsche 914-2  0.98    above
## Fiat X1-9                     Fiat X1-9  1.20    above
## Honda Civic                 Honda Civic  1.71    above
## Lotus Europa               Lotus Europa  1.71    above
## Fiat 128                       Fiat 128  2.04    above
## Toyota Corolla           Toyota Corolla  2.29    above
```
Now, lets plot the diverging bar plot.  When using gKnit, there is no need to call
'R.awt' to create a plotting device, since gKnit does take care of it. Galaaz 
provides integration with ggplot. The interested reader should check online for more
information on ggplot, since it is outside the scope of this manual describing 
how ggplot works. We give here but a brief description on how this plot is generated.

ggplot implements the 'grammar of graphics'. In this approach, plots are build by
adding layers to the plot.  On the first layer we describe what we want on the 'x'
and 'y' axis of the plot.  In this case, we have 'car_name' on the 'x' axis and 
'mpg\_z' on the 'y' axis. Then the type of graph is specified by adding
'geom\_bar' (for a bar graph).  We specify that our bars should be filled using 
'mpg\_type', which is either 'above' or 'bellow' giving then two colours for
filling. On the next layer we specify the labels for the graph, then we add the
title and subtitle.  Finally, in a bar chart usually bars go on the vertical direction,
but in this graph we want the bars to be horizontally layed so we add 'coord\_flip'.


```ruby
require 'ggplot'

puts @mtcars.ggplot(E.aes(x: :car_name, y: :mpg_z, label: :mpg_z)) +
  R.geom_bar(E.aes(fill: :mpg_type), stat: 'identity', width: 0.5) +
  R.scale_fill_manual(name: 'Mileage',
                      labels: R.c('Above Average', 'Below Average'),
                      values: R.c('above': '#00ba38', 'below': '#f8766d')) +
  R.labs(subtitle: "Normalised mileage from 'mtcars'",
         title: "Diverging Bars") + 
  R.coord_flip
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

