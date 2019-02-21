# Find default values for variables specified as args
#
module Puppet::Parser::Functions
  newfunction(:dump_values, :type => :rvalue) do |args|
    Hash[args.flatten.map { |arg| [arg, lookupvar(arg)] }]
  end
end
