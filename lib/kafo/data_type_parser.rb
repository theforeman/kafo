require 'kafo/data_type'

module Kafo
  class DataTypeParser
    TYPE_DEFINITION = /^type\s+([^\s=]+)\s*=\s*(.+?)(\s+#.*)?\s*$/

    attr_reader :types

    def initialize(manifest)
      @logger = KafoConfigure.logger
      @types = {}
      manifest.each_line do |line|
        if (type = TYPE_DEFINITION.match(line.force_encoding("UTF-8")))
          @types[type[1]] = type[2]
        end
      end
    end

    def register
      @types.each do |name,target|
        @logger.debug("Registering extended data type #{name}")
        DataType.register_type(name, target)
      end
    end
  end
end
