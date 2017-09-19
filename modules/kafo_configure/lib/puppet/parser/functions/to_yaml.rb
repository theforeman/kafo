# Returns the given argument as a string containing YAML, with an end of
# document marker.
#
module Puppet::Parser::Functions
  newfunction(:foreman_to_yaml, :type => :rvalue) do |args|
    dump = if args.all? { |a| a.is_a?(Hash) }
             args.inject({}) { |m,a| m.merge(a) }
           else
             args.first
           end
    YAML.dump(dump) + "\n...\n"
  end
end
