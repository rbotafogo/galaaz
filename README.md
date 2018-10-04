# Running Ruby and R - The Polyglot Environment

TruffleRuby (the Polyglot implementation of Ruby) can access, through the Polyglot interface, any other
language available in the environment. For instance, in the code bellow, TruffleRuby makes a call to
JavaScript:

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

