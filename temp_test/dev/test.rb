require 'rake'

task :task1 do
 puts "Hello World"
end

Rake::Task["task1"].invoke
