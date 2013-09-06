require 'rake/testtask'
require "bundler/gem_tasks"

Rake::TestTask.new do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

