source 'https://rubygems.org'

# Specify your gem's dependencies in kafo.gemspec
gemspec

  if RUBY_VERSION >= '2.0'
    gem 'logging', '< 3.0.0'
    gem 'highline', '>= 1.6.21', '< 2.0'
    gem 'json_pure'
  else
    gem 'logging', '< 2.0.0'
    gem 'highline', '>= 1.6.21', '< 1.7'
    gem 'json_pure', '< 2.0.0'
  end

puppet_version = ENV['PUPPET_VERSION']
puppet_spec = puppet_version ? "~> #{puppet_version}" : '< 5.0.0'
gem 'puppet', puppet_spec

if puppet_version.nil? || puppet_version >= '4.0'
  gem 'puppet-strings'
end
