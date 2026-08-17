# frozen_string_literal: true
# Minimal post-install check: gem is on LOAD_PATH, R starts, bridge eval works.

require 'galaaz'

vec = R.c(1, 2, 3)
text = vec.to_s
puts text
unless text.include?('1') && text.include?('2') && text.include?('3')
  abort("cold-install smoke: unexpected R.c output: #{text.inspect}")
end

ver = R.getRversion
puts ver
abort('cold-install smoke: empty R version') if ver.to_s.strip.empty?

puts 'cold-install smoke: OK'
