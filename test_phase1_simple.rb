#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'new_bridge'

puts "Test 1: Basic SessionClient with pre-compiled .so"
so_path = File.expand_path('ext/new_bridge/galaaz_gatekeeper.so', __dir__)
cpp_path = File.expand_path('ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__)

source = File.exist?(so_path) ? so_path : cpp_path
puts "Using source: #{source}"

client = NewBridge::SessionClient.new(source_path: source)
puts "Starting client..."
start_time = Time.now
client.start
puts "Client started in #{Time.now - start_time} seconds"

puts "Running eval_r('1L + 1L')..."
result = client.eval_r("1L + 1L")
puts "Result: #{result.inspect}"

if result['value'] == 2
  puts "SUCCESS: Phase 1 basic test passed"
else
  puts "FAILURE: Expected value 2, got #{result['value']}"
  exit 1
end

client.stop
puts "Done"
