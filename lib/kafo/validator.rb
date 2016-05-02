# encoding: UTF-8
module Kafo
  class Validator

    def initialize
      @logger = KafoConfigure.logger
    end

    def validate_absolute_path(args)
      args.each do |arg|
        unless arg.to_s.start_with?('/')
          @logger.error "#{arg.inspect} is not an absolute path."
          return false
        end
      end
      return true
    end

    def validate_array(args)
      args.each do |arg|
        unless arg.is_a?(Array)
          @logger.error "#{arg.inspect} is not a valid array."
          return false
        end
      end
      return true
    end

    def validate_bool(args)
      args.each do |arg|
        unless arg.is_a?(TrueClass) || arg.is_a?(FalseClass)
          @logger.error "#{arg.inspect} is not a valid boolean."
          return false
        end
      end
      return true
    end

    def validate_hash(args)
      args.each do |arg|
        unless arg.is_a?(Hash)
          @logger.error "#{arg.inspect} is not a valid hash."
          return false
        end
      end
      return true
    end

    def validate_integer(args)
      value = args[0]
      max = args[1]
      min = args[2]
      int = Integer(value.to_s)
      if min && int < min.to_i
        @logger.error "#{value} must be at least #{min}."
        return false
      end
      if max && int > max.to_i
        @logger.error "#{value} must be less than #{max}."
        return false
      end
      return true
    rescue TypeError, ArgumentError
      @logger.error "#{value.inspect} is not a valid integer."
      return false
    end

    # Non-standard validation is from theforeman/foreman_proxy module
    def validate_listen_on(args)
      valid_values = ['http', 'https', 'both']
      args.each do |arg|
        unless valid_values.include?(arg)
          @logger.error "#{arg.inspect} is not a valid value.  Valid values are: #{valid_values.join(", ")}"
          return false
        end
      end
      return true
    end

    def validate_re(args)
      value = args[0]
      regexes = args[1]
      regexes = [regexes] unless regexes.is_a?(Array)
      message = args[2] || "#{value.inspect} does not match the accepted inputs: #{regexes.join(", ")}"

      if regexes.any? { |rx| value =~ Regexp.compile(rx) }
        return true
      else
        @logger.error message
        return false
      end
    end

    def validate_string(args)
      args.each do |arg|
        unless arg.is_a?(String)
          @logger.error "#{arg.inspect} is not a valid string."
          return false
        end
      end
      return true
    end

    def method_missing(method, *args, &block)
      if method.to_s.start_with?('validate_')
        @logger.debug "Skipping validation with #{method} as it's not implemented in Kafo"
        return true
      else
        super
      end
    end
  end
end
