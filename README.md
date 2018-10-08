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

# Running Ruby and R - The Polyglot Environment

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

Calling R is similar to the above. For example, in R, method 'c' concatenates its arguments making a vector:

    vec = Polyglot.eval('R', 'c').call(1, 2, 3) 
    puts vec[0] 
    p vec
    > 1
    > #<Truffle::Interop::Foreign@5d03df76> 

As can be seen, vec is a vector with the first element (indexed at 0 - Ruby indexing) is 1.
Inspecting vec, show that it is a Truffle::Interop object. Although it is possible to work with
Interop objects in a program, doing so is hard and error prone. Bellow, we show how integration of
Ruby and R can greatly simplify the development of Polyglot application.

# Installation

* gu install ruby
* run post_install_hook.sh (as instructed)
* gu install R
* configure_fastr (as instructed)
* gu rebuild-images ruby (might not be necessary - time and cpu intensive)
* gem install galaaz
* execute 'galaaz' to see a slide show with many graphics
* execute 'galaaz -T' to see all available examples


