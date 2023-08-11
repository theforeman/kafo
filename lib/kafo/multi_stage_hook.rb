module Kafo
  class MultiStageHook
    def initialize(name, registry, types)
      default_name = name

      types.each do |hook_type|
        self.class.send(:define_method, hook_type) do |hook_name = nil, &block|
          registry.send(:register, hook_type, hook_name || default_name, &block)
        end
      end
    end
  end
end
