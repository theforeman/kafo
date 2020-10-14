# encoding: UTF-8
require 'clamp'

module Kafo
  module HelpBuilders
    DEFAULT_GROUP_NAME   = 'Basic'
    DEFAULT_MODULE_NAME  = 'Generic'
    IGNORE_IN_GROUP_NAME = /\s*parameters:?/

    class Base < ::Clamp::Help::Builder
      include StringHelper

      def initialize(params)
        super()
        @params = params
      end

      def add_list(heading, items)
        return if items.empty?
        if heading == 'Options'
          puts "\n#{heading}:"

          data = by_module(items)
          sorted_keys(data).each do |section|
            if section == 'Generic'
              add_list(header(1, section), data[section])
            else
              add_module(section, data[section])
            end
          end
        else
          super
        end
      end

      private

      # sorts modules by name with leaving Generic as first one
      def sorted_keys(modules_hash)
        keys = modules_hash.keys
        keys.reject! { |k| k == DEFAULT_MODULE_NAME }
        [ DEFAULT_MODULE_NAME ] + keys.sort
      end

      def add_module(name, items)
        raise NotImplementedError, 'add module not defined'
      end

      def header(level, text)
        level(level) + ' ' + text
      end

      def module_header(name)
        "\n" + header(1, 'Module ' + name)
      end

      def level(n)
        '=' * n
      end

      def by_parameter_groups(items)
        data = Hash.new { |h, k| h[k] = [] }
        params_mapping(items).each do |item, param|
          data[group(param)].push item
        end
        data
      end

      def group(param)
        name = param.groups.reverse.find { |group| group.include?('parameters') }
        name.nil? ? DEFAULT_GROUP_NAME : name.sub(IGNORE_IN_GROUP_NAME, '')
      end

      def by_module(help_items)
        data = Hash.new { |h, k| h[k] = [] }
        params_mapping(help_items).each do |item, param|
          data[param.nil? ? DEFAULT_MODULE_NAME : param.module_name].push item
        end
        data
      end

      def params_mapping(items)
        items.map { |i| [i, parametrization[i.help.first.strip]] }
      end

      def parametrization
        @parametrization ||= begin
          @params.inject({}) do |h,p|
            h.update(parametrize(p) => p, parametrize(p, 'reset-') => p)
          end
        end
      end
    end
  end
end
