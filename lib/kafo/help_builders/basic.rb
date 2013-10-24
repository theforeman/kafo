module HelpBuilders
  class Basic < Base
    def add_module(name, items)
      data = by_parameter_groups(items)
      add_list(module_header(name), data['Basic'])
    end
  end
end
