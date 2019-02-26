source 'https://rubygems.org'

# Specify your gem's dependencies in kafo.gemspec
gemspec

gem 'json_pure'

if RUBY_VERSION < '2.1'
  # Technically not needed, but avoids issues with bundler versions
  gem 'rdoc', '< 5.0.0'
elsif RUBY_VERSION < '2.2'
  gem 'rdoc', '< 6.0.0'
end

if ENV['PUPPET_VERSION']
  gem 'puppet', "~> #{ENV['PUPPET_VERSION']}"
else
  gem 'puppet', '>= 4.5.0', '< 7.0.0'
end

gem 'puppet-strings', RUBY_VERSION >= '2.1' ? '>= 1.2.1' : '~> 1.2.1'

group :puppet_module do
  gem 'metadata-json-lint'
  gem 'puppetlabs_spec_helper'
end
