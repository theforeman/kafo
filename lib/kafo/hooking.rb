module Kafo
  class Hooking

    attr_accessor :hooks, :kafo

    def initialize
      self.hooks = Hash.new { |h, k| h[k] = {} }
    end

    def logger
      KafoConfigure.logger
    end

    def execute(group)
      logger.info "Executing hooks in group #{group}"
      self.hooks[group].each_pair do |name, hook|
        result = hook.call(kafo)
        logger.debug "Hook #{name} returned #{result.inspect}"
      end
      logger.info "All hooks in group #{group} finished"
    end

    def register_pre(name, &block)
      register(:pre, name, &block)
    end

    def register_post(name, &block)
      register(:post, name, &block)
    end

    private

    def register(group, name, &block)
      self.hooks[group][name] = block
    end
  end
end
