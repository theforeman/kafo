require 'rake/testtask'
require "bundler/gem_tasks"
load 'tasks/jenkins.rake'

Rake::TestTask.new('test:unit') do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/kafo/**/*_test.rb']
  t.verbose = true
end

Rake::TestTask.new('test:acceptance') do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/acceptance/*_test.rb']
  t.verbose = true
end

CLEAN.include 'test/tmp'

task :test => ['test:unit', 'test:acceptance']
