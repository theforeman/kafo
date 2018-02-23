require 'kafo/data_type'

module Kafo
  DataType.register_type('Data', 'Any')
  DataType.register_type('Default', 'Enum["default"]')

  # pre-Puppet 4 Kafo data types
  DataType.register_type('array', 'Optional[Array]')
  DataType.register_type('boolean', 'Optional[Boolean]')
  DataType.register_type('hash', 'Optional[Hash]')
  DataType.register_type('integer', 'Optional[Integer]')
  DataType.register_type('string', 'Optional[String]')
end
