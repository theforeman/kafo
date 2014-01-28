# Find default values for variables specified as args
#
module Puppet::Parser::Functions
  newfunction(:dump_values) do |args|
    options = []
    options<< false if Puppet::PUPPETVERSION.start_with?('2.6')
    data = Hash[args.map { |arg| [arg, lookupvar(arg, *options) || arg] }]
    dump_dir = YAML.load_file(lookupvar('kafo_config_file'))[:default_values_dir]
    File.open("#{dump_dir}/default_values.yaml", 'w') { |file| file.write(YAML.dump(data)) }
  end
end
