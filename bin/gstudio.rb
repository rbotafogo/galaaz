require 'galaaz'
require 'ggplot'
require 'irb/completion'
require 'pp'

IRB.conf[:PROMPT][:CUSTOM] = {
  :PROMPT_I => "galaaz >> ",
  :PROMPT_S => "%l>> ",
  :PROMPT_C => ".. ",
  :PROMPT_N => ".. ",
  :RETURN => "=> %s\n"
}

IRB.conf[:PROMPT_MODE] = :CUSTOM
IRB.conf[:AUTO_INDENT] = true
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = '~/.galaaz.history'
IRB.conf[:ECHO] = false

# history command
def history(count = 0)

  # Get history into an array
  history_array = Readline::HISTORY.to_a

  # if count is > 0 we'll use it.
  # otherwise set it to 0
  count = count > 0 ? count : 0

  if count > 0
    from = hist.length - count
    history_array = history_array[from..-1] 
  end

  print history_array.join("\n")
end
