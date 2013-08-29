# Orders modules names according to kafo.yaml
#
# if order was specified we take all modules in this order, if there are
# other modules that were not ordered, we put them at the end in non-specified
# order
module Puppet::Parser::Functions
  newfunction(:kafo_ordered, :type => :rvalue) do |args|
    order = YAML.load_file('config/kafo.yaml')[:order]
    if order.nil?
      args[0]
    else
      result = []
      base = args[0].clone
      order.each do |name|
        result<< base.delete(name)
      end
      result + base
    end
  end
end

