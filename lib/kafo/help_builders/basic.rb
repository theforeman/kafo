# encoding: UTF-8

module Kafo
  module HelpBuilders
    class Basic < Base
      def add_module(name, items)
        pruned = except_resets(items)
        pruned = except_advanced(pruned)
        data = by_parameter_groups(pruned)
        add_list(module_header(name), data[DEFAULT_GROUP_NAME])
      end

      def add_list(heading, items)
        pruned = except_advanced(items)
        super(heading, pruned)
      end

      def string
        super + "\nOnly commonly used options have been displayed.\nUse --full-help to view the complete list."
      end

      private

      def except_resets(items)
        items.select { |i| !i.help.first.strip.start_with?('--reset-') || !i.help.last.include?('to the default value (') }
      end

      def except_advanced(items)
        items.reject { |item| item.respond_to?(:advanced?) && item.advanced? }
      end
    end
  end
end
