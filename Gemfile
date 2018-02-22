source 'https://rubygems.org'

# Specify your gem's dependencies in kafo.gemspec
gemspec

gem 'json_pure'
gem 'rdoc', '< 6.0.0' if RUBY_VERSION < '2.2'

puppet_version = ENV['PUPPET_VERSION'] || '5.0'
gem 'puppet', "~> #{puppet_version}"
gem 'puppet-strings' if puppet_version >= '4.0'
