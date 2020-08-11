require 'kafo/hook_context'

module Kafo
  class Hooking
    # pre_migrations - just after kafo reads its configuration - useful for config file updates. Only in this stage it is posible to request config reload (`Kafo.request_config_reload`) to get in our changes
    # boot - before kafo is ready to work, useful for adding new app arguments, logger won't work yet
    # init - just after hooking is initialized and kafo is configured, parameters have no values yet
    # pre_values - just before value from CLI is set to parameters (they already have default values)
    # pre_validations - just after system checks and before validations are executed (and before interactive wizard is started), at this point all parameter values are already set but not yet stored in answer file
    # pre_commit - after validations or interactive wizard have completed, all parameter values are set but not yet stored in the answer file
    # pre - just before puppet is executed to converge system
    # post - just after puppet is executed to converge system
    TYPES = [:pre_migrations, :boot, :init, :pre, :post, :pre_values, :pre_validations, :pre_commit]

    attr_accessor :hooks, :kafo

    def initialize
      self.hooks = Hash.new { |h, k| h[k] = {} }
      @loaded = false
    end

    def logger
      KafoConfigure.logger
    end

    def load
      base_dirs = [File.join([KafoConfigure.root_dir, 'hooks']), KafoConfigure.config.app[:hook_dirs]].flatten
      base_dirs.each do |base_dir|
        TYPES.each do |hook_type|
          dir = File.join(base_dir, hook_type.to_s)
          Dir.glob(dir + "/*.rb").sort.each do |file|
            logger.debug "Loading hook #{file}"
            hook = File.read(file)
            hook_block = proc { instance_eval(hook, file, 1) }
            register(hook_type, file, &hook_block)
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
      ::Logging.mdc['stage'] = group
      logger.info "Executing hooks in group #{group}"
      self.hooks[group].keys.sort_by(&:to_s).each do |name|
        hook = self.hooks[group][name]
        result = HookContext.execute(self.kafo, &hook)
        logger.debug "Hook #{name} returned #{result.inspect}"
      end
      logger.info "All hooks in group #{group} finished"
      ::Logging.mdc.delete('stage')
    end

    def register_pre_migrations(name, &block)
      register(:pre_migrations, name, &block)
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

    def register_pre_validations(name, &block)
      register(:pre_validations, name, &block)
    end

    def register_pre_commit(name, &block)
      register(:pre_commit, name, &block)
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
