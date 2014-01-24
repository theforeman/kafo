# Translates module name to proper class name
# This is especially useful if you want to give a nice name to
# a configuration option and still want to use some class with
# less readable name e.g. puppetmaster -> puppet::server
# - if the argument matches known module name, it returns corresponding class name
# - otherwise it returns argument that was specified
#
module Puppet::Parser::Functions
  newfunction(:class_name, :type => :rvalue) do |args|
    mapping = YAML.load_file(lookupvar('kafo_config_file'))[:mapping]
    mod = args[0].to_sym
    mapping[mod].nil? ? mod : "#{mapping[mod][:dir_name]}::#{mapping[mod][:manifest_name].gsub('/', '::')}"
  end
end

