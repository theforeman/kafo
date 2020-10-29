# encoding: UTF-8
module Kafo
  module StringHelper
    def dashize(string)
      string.tr('_', '-')
    end

    alias :d :dashize

    def underscore(string)
      string.tr('-', '_')
    end

    alias :u :underscore

    def with_prefix(param)
      prefix = KafoConfigure.config.app[:no_prefix] ? '' : "#{d(param.module_name)}-"
      "#{prefix}#{d(param.name)}"
    end

    def parametrize(param, prefix = '')
      "--#{prefix}#{with_prefix(param)}"
    end
  end
end
