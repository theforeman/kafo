# Loads a kafo master password from kafo.yaml
#
module Puppet::Parser::Functions
  newfunction(:load_kafo_answer_file, :type => :rvalue) do |args|
    YAML.load_file(lookupvar('kafo_config_file'))[:answer_file]
  end
end

