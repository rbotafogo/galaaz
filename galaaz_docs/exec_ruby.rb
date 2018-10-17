require 'stringio'

def exec_ruby(code)
  # Set up standard output as a StringIO object.
  foo = StringIO.new
  $stdout = foo

  eval code

  out = $stdout.string
  
  # return $stdout to standard output
  $stdout = STDOUT

  # return everything that was outputed
  out
end
