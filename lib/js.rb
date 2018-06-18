module JS

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------
  
  def self.eval(string)
    Polyglot.eval('js', string)
  end

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.method_missing(symbol, *args)

    name = symbol.to_s
    # convert '__' to '.'
    name.gsub!(/__/,".")
    # Method 'rclass' is a substitute for R method 'class'.  Needed, as 'class' is also
    # a Ruby method on an object
    name.gsub!("rclass", "class")

    eval(name).call(*args)
    
  end

end
