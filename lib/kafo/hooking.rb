module Kafo
  class Hooking
    # boot - before kafo is ready to work, useful for adding new app arguments, logger won't work yet
    # init - just after hooking is initialized and kafo is configured, parameters have no values yet
    # pre_values - just before value from CLI is set to parameters (they already have default values)
    # pre - just before puppet is executed to converge system
    # post - just after puppet is executed to converge system
    TYPES = [:boot, :init, :pre, :post, :pre_values]

    attr_accessor :hooks, :kafo

    def initialize
      self.hooks = Hash.new { |h, k| h[k] = {} }
      @loaded = false
    end

    def logger
      KafoConfigure.logger
    end

    def load
      base_dirs = [File.join([KafoConfigure.root_dir, 'hooks']), KafoConfigure.config.app[:hook_dirs]]
      base_dirs.each do |base_dir|
        TYPES.each do |hook_dir|
          dir = File.join([base_dir, hook_dir.to_s])
          Dir.glob(dir + "/*.rb").sort.each do |file|
            logger.debug "Loading hook #{file}"
            require file
          end
        end
        @loaded = true
      end
      self
    end

    def loaded?
      @loaded
    end

    def execute(group)
      logger.info "Executing hooks in group #{group}"
      self.hooks[group].each_pair do |name, hook|
        result = hook.call(kafo)
        logger.debug "Hook #{name} returned #{result.inspect}"
      end
      logger.info "All hooks in group #{group} finished"
    end

    def register_boot(name, &block)
      register(:boot, name, &block)
    end

    def register_init(name, &block)
      register(:init, name, &block)
    end

    def register_pre_values(name, &block)
      register(:pre_values, name, &block)
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
