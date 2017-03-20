module Kafo
  class DataType
    def self.new_from_string(str)
      keyword_re = /\A([\w:]+)(?:\[(.*)\])?\z/m.match(str)
      raise ConfigurationException, "data type not recognized #{str}" unless keyword_re

      type = @keywords[keyword_re[1]]
      raise ConfigurationException, "unknown data type #{keyword_re[1]}" unless type

      if type.is_a?(String)
        new_from_string(type)
      else
        args = if keyword_re[2]
                 hash_re = keyword_re[2].match(/\A\s*\{(.*)\}\s*\z/m)
                 if hash_re
                   [parse_hash(hash_re[1])]
                 else
                   split_arguments(keyword_re[2])
                 end
               else
                 []
               end
        type.new(*args)
      end
    end

    def self.register_type(keyword, type)
      @keywords ||= {}
      raise ArgumentError, "Data type #{keyword} is already registered, cannot be re-registered" if @keywords.has_key?(keyword)
      @keywords[keyword] = type
    end

    def self.types
      @keywords ? @keywords.keys : []
    end

    def self.unregister_type(keyword)
      @keywords.delete(keyword) if @keywords
    end

    def self.split_arguments(input)
      input.scan(%r{
        \s*
          (?:
            ["'/](.*?)["'/] # quoted string, or regexp argument
            |
            ([\w:]+ (?:\[.+\])?) # bare words, or Type::Name, or Type::Name[args..]
          )
        \s*
        (?:,|$) # match to end of comma-separated arg, or the last arg
      }mx).flatten.compact
    end

    def self.parse_hash(input)
      Hash[input.scan(%r{\s*["'/]?([\w:]+(?:\[[^\]]+\])?|.+?)["'/]?\s*=>\s*["'/]?([\w:]+(?:\[[^\]]+\])?|.+?)["'/]?\s*(?:,|$)}m)]
    end

    # public interface

    def condition_value(value)
      value.inspect
    end

    def dump_default(value)
      %{"#{value}"}
    end

    def multivalued?
      false
    end

    def to_s
      self.class.name.split('::').last.downcase
    end

    def typecast(value)
      value == 'UNDEF' ? nil : value
    end

    def valid?(value, errors = [])
      true
    end
  end
end

require 'kafo/data_types/aliases'
require 'kafo/data_types/any'
require 'kafo/data_types/array'
require 'kafo/data_types/boolean'
require 'kafo/data_types/enum'
require 'kafo/data_types/float'
require 'kafo/data_types/hash'
require 'kafo/data_types/integer'
require 'kafo/data_types/not_undef'
require 'kafo/data_types/numeric'
require 'kafo/data_types/optional'
require 'kafo/data_types/pattern'
require 'kafo/data_types/regexp'
require 'kafo/data_types/scalar'
require 'kafo/data_types/string'
require 'kafo/data_types/struct'
require 'kafo/data_types/tuple'
require 'kafo/data_types/type_reference'
require 'kafo/data_types/undef'
require 'kafo/data_types/variant'
