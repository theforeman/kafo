# Loads a kafo master password from kafo.yaml
#

# Loading the decrypt function explicitly so that is always available in templates
# when calling scope.function_decrypt([@password])
require File.expand_path('../decrypt', __FILE__)

module Puppet::Parser::Functions
  newfunction(:load_kafo_password, :type => :rvalue) do |args|
    YAML.load_file(lookupvar('kafo_config_file'))[:password]
  end
end

