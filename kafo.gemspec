# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
$LOAD_PATH.unshift(lib + '/kafo')
$LOAD_PATH.unshift(lib + '/kafo/params')
require 'kafo/version'

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

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  # puppet manifests parsing
  spec.add_dependency 'puppet'
  spec.add_dependency 'rdoc', '~> 3.0'
  # better logging
  spec.add_dependency 'logging'
  # CLI interface
  spec.add_dependency 'clamp'
  # interactive mode
  spec.add_dependency 'highline'

end
