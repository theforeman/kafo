require 'yaml'

module Kafo
  module AnswerFile
    class Base

      attr_reader :answers, :filename

      def initialize(filename)
        @filename = filename
        @answers = YAML.load_file(@filename)
        validate
      end

      def save(data, config_header)
        FileUtils.touch @filename
        File.chmod 0600, @filename
        File.open(@filename, 'w') { |f| f.write(config_header + format(YAML.dump(data))) }
      end

      def puppet_classes
        raise NoMethodError
      end

      def class_enabled?(puppet_class)
        raise NoMethodError
      end

      def parameters_for_class(puppet_class)
        raise NoMethodError
      end

      def validate
        raise NoMethodError
      end

    end
  end
end
