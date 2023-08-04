require 'rake/testtask'
require "bundler/gem_tasks"
load 'tasks/jenkins.rake'

Rake::TestTask.new('test:ruby') do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/**/*_test.rb'] - FileList['test/tmp/**/*_test.rb']
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

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop) do |task|
  # These make the rubocop experience maybe slightly less terrible
  task.options = ['--display-cop-names', '--display-style-guide', '--extra-details']
  # Use Rubocop's Github Actions formatter if possible
  task.formatters << 'github' if ENV['GITHUB_ACTIONS'] == 'true'
end

CLEAN.include 'test/tmp'

task :test => ['test:ruby', 'test:puppet_modules']
