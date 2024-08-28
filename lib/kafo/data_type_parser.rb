require 'kafo/data_type'

module Kafo
  class DataTypeParser
    TYPE_DEFINITION = /^type\s+([^\s=]+)\s*=\s*(.+?)(\s+#.*)?\s*$/

    attr_reader :types

    def initialize(manifest)
      @logger = KafoConfigure.logger

      lines = []
      type_line_without_newlines = +''
      manifest.each_line do |line|
        line = line.force_encoding("UTF-8").strip
        next if line.start_with?('#') || line.empty?

        line = line.split(' #').first.strip
        if line =~ TYPE_DEFINITION
          lines << type_line_without_newlines
          type_line_without_newlines = line
        else
          type_line_without_newlines << line
        end
      end
      lines << type_line_without_newlines

      @types = {}
      lines.each do |line|
        if (type = TYPE_DEFINITION.match(line))
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
