# Find default values for variables specified as args
#
module Puppet::Parser::Functions
  newfunction(:dump_values, :type => :rvalue) do |args|
    options = []
    options<< false if Puppet::PUPPETVERSION.start_with?('2.6')
    data = args.flatten.map do |arg|
      found_value = lookupvar(arg, *options)
      [arg, found_value]
    end
    Hash[data]
  end
end
