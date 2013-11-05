# encoding: UTF-8

module Kafo
  module HelpBuilders
    class Advanced < Base
      def add_module(name, items)
        data = by_parameter_groups(items)
        if data.keys.size > 1
          puts module_header(name + ':')
          data.keys.each do |group|
            add_list(header(2, group), data[group])
          end
        else
          add_list(module_header(name), data[data.keys.first])
        end
      end
    end
  end
end
