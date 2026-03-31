include model local repro
================

``` include
require 'galaaz'

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

  def partition(field)

    train_index =
      R.createDataPartition(@data.send(field), p: @percet_train,
                            list: false, times: 1)
    @train = @data[train_index, :all]
    @test = @data[-train_index, :all]
    
  end
  
end
```

    ## Failed to install packages: [1] "caret". Check stderr output above for [RUBY] debug messages.

    ## /home/rbotafogo/desenv_linux/galaaz/lib/R_interface/r.rb:143:in 'install_rlibs'
    ## /home/rbotafogo/desenv_linux/galaaz/lib/R_interface/r.rb:154:in 'install_and_loads'
    ## /home/rbotafogo/desenv_linux/galaaz/lib/util/exec_ruby.rb:173:in 'exec_ruby'
    ## org/jruby/RubyKernel.java:1268:in 'eval'
    ## /home/rbotafogo/desenv_linux/galaaz/lib/util/exec_ruby.rb:169:in 'exec_ruby'
    ## /home/rbotafogo/desenv_linux/galaaz/lib/gknit/knitr_engine.rb:770:in 'block in initialize'
    ## org/jruby/RubyBasicObject.java:2695:in 'instance_eval'
    ## org/jruby/RubyBasicObject.java:2723:in 'instance_eval'
    ## /home/rbotafogo/desenv_linux/galaaz/lib/gknit/knitr_engine.rb:741:in 'block in initialize'
    ## /home/rbotafogo/desenv_linux/galaaz/lib/gknit/include_engine.rb:54:in 'block in initialize'
    ## /home/rbotafogo/desenv_linux/galaaz/lib/R_interface/new_bridge_adapter.rb:233:in 'block in register_callback_proc_stub'
    ## /home/rbotafogo/desenv_linux/galaaz/lib/new_bridge/session_client.rb:344:in 'block in handle_call'

uninitialized constant RC::Modelorg/jruby/RubyModule.java:4875:in
‘const_missing’
/home/rbotafogo/desenv_linux/galaaz/lib/util/exec_ruby.rb:171:in
‘exec_ruby’ org/jruby/RubyKernel.java:1268:in ‘eval’
/home/rbotafogo/desenv_linux/galaaz/lib/util/exec_ruby.rb:169:in
‘exec_ruby’
/home/rbotafogo/desenv_linux/galaaz/lib/gknit/knitr_engine.rb:770:in
‘block in initialize’ org/jruby/RubyBasicObject.java:2695:in
‘instance_eval’ org/jruby/RubyBasicObject.java:2723:in ‘instance_eval’
/home/rbotafogo/desenv_linux/galaaz/lib/gknit/knitr_engine.rb:741:in
‘block in initialize’
/home/rbotafogo/desenv_linux/galaaz/lib/R_interface/new_bridge_adapter.rb:233:in
‘block in register_callback_proc_stub’
/home/rbotafogo/desenv_linux/galaaz/lib/new_bridge/session_client.rb:344:in
‘block in handle_call’
