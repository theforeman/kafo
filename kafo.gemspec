# coding: utf-8
require File.join(File.expand_path(File.dirname(__FILE__)), 'lib', 'kafo', 'version')

Gem::Specification.new do |spec|
  spec.name          = "kafo"
  spec.version       = Kafo::VERSION
  spec.authors       = ["Marek Hulan"]
  spec.email         = ["ares@igloonet.cz"]
  spec.description   = %q{A gem for making installations based on puppet user friendly}
  spec.summary       = %q{If you write puppet modules for installing your software, you can use kafo to create powerful installer}
  spec.homepage      = "https://github.com/theforeman/kafo"
  spec.license       = "GPLv3+"

  spec.files         = Dir['bin/*'] + Dir['config/*'] + Dir['lib/**/*'] + Dir['modules/**/*'] +
                       ['LICENSE.txt', 'Rakefile', 'README.md']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'ansi'
  spec.add_development_dependency 'minitest', '~> 4.0'
  spec.add_development_dependency 'simplecov', '< 0.9'
  spec.add_development_dependency 'ci_reporter', '~> 1.9.0'

  spec.add_dependency 'kafo_wizards'
  spec.add_dependency 'ansi'
  # puppet module parsing
  spec.add_dependency 'kafo_parsers'
  spec.add_dependency 'puppet', '< 4.0.0'
  # better logging
  spec.add_dependency 'logging', '< 3.0.0'
  # CLI interface
  spec.add_dependency 'clamp', '>= 0.6.2'
  # interactive mode
  spec.add_dependency 'highline', '>= 1.6.21', '< 2.0'
  # ruby progress bar
  spec.add_dependency 'powerbar'
end
