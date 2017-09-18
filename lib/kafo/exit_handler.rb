module Kafo
  class ExitHandler
    attr_accessor :cleanup_paths, :exit_code, :logger

    def initialize
      @cleanup_paths = []
      @exit_code = 0
      @logger = KafoConfigure.logger
    end

    def error_codes
      @error_codes ||= {
          :invalid_system => 20,
          :invalid_values => 21,
          :manifest_error => 22,
          :no_answer_file => 23,
          :unknown_module => 24,
          :defaults_error => 25,
          :unset_scenario => 26,
          :scenario_error => 27,
          :missing_argument => 28,
          :insufficient_permissions => 29,
          :puppet_version_error => 30
      }
    end

    def exit(code, &block)
      @exit_code = translate_exit_code(code)
      block.call if block
      KafoConfigure.logger.debug "Exit with status code: #{@exit_code} (signal was #{code})"
      KafoConfigure.logger.dump_errors unless KafoConfigure.verbose
      cleanup
      Kernel.exit(@exit_code)
    end

    def translate_exit_code(code)
      return code if code.is_a?(Integer)
      if error_codes.has_key?(code)
        return error_codes[code]
      else
        raise "Unknown code #{code}"
      end
    end

    def cleanup
      # make sure default values are removed from /tmp
      (self.cleanup_paths + ['/tmp/default_values.yaml']).each do |file|
        logger.debug "Cleaning #{file}"
        FileUtils.rm_rf(file)
      end
    end

    def register_cleanup_path(path)
      self.cleanup_paths<< path
    end

  end
end
