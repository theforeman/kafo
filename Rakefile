require 'rake/testtask'
require "bundler/gem_tasks"
load 'tasks/jenkins.rake'

Rake::TestTask.new('test:ruby') do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

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

namespace 'test' do
  desc 'Run Puppet module tests'
  task :puppet_modules do
    Dir['modules/*'].each do |mod|
      Dir.chdir(mod) do
        `rake release_checks`
      end
    end
  end
end

CLEAN.include 'test/tmp'

task :test => ['test:ruby', 'test:puppet_modules']
