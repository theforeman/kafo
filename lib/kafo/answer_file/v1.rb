require 'kafo/answer_file/base'

module Kafo
  module AnswerFile
    class V1 < Base

      def puppet_classes
        @answers.keys.sort
      end

      def parameters_for_class(puppet_class)
        params = @answers[puppet_class]
        params.is_a?(Hash) ? params : {}
      end

      def class_enabled?(puppet_class)
        value = @answers[puppet_class.is_a?(String) ? puppet_class : puppet_class.identifier]
        !!value || value.is_a?(Hash)
      end

      def validate
        invalid = @answers.reject do |puppet_class, value|
          value.is_a?(Hash) || [true, false].include?(value)
        end

        unless invalid.empty?
          fail InvalidAnswerFile, "Answer file at #{@filename} has invalid values for #{invalid.keys.join(', ')}. Please ensure they are either a hash or true/false."
        end
      end

    end
  end
end
