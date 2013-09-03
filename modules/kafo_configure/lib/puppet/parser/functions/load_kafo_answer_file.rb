# Loads a answer file
#
# it can be specified either as a $kafo_answer_file variable or it's read from config file
module Puppet::Parser::Functions
  newfunction(:load_kafo_answer_file, :type => :rvalue) do |args|
    answer_file = lookupvar('kafo_answer_file')
    if answer_file && !answer_file.empty?
      answer_file
    else
      YAML.load_file(lookupvar('kafo_config_file'))[:answer_file]
    end
  end
end
