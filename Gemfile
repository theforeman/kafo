source 'https://rubygems.org'

# Specify your gem's dependencies in kafo.gemspec
gemspec

gem 'json_pure'

if ENV['PUPPET_VERSION']
  gem 'puppet', "~> #{ENV['PUPPET_VERSION']}"
else
  gem 'puppet', '>= 4.5.0', '< 8.0.0'
end

gem 'puppet-strings', '>= 1.2.1'
# https://github.com/theforeman/kafo_parsers/pull/49
gem 'kafo_parsers', github: 'ekohl/kafo_parsers', branch: 'bulk-strings'

group :puppet_module do
  gem 'metadata-json-lint'
  gem 'puppetlabs_spec_helper'
end

group :test do
  gem 'rubocop'
end
