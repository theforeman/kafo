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

puppet_version = ENV['PUPPET_VERSION']
puppet_spec = puppet_version ? "~> #{puppet_version}" : '< 6.0.0'
gem 'puppet', puppet_spec

if puppet_version.nil? || puppet_version >= '4.0'
  gem 'puppet-strings'
end
