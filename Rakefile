require 'rake/testtask'
require "bundler/gem_tasks"
load 'tasks/jenkins.rake'

Rake::TestTask.new do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

