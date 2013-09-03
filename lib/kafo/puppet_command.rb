class PuppetCommand
  def initialize(command, options = [])
    @command = command
    @options = options.push("--modulepath #{modules_path}")
    @logger  = Logging.logger.root
  end

  def command
    result = [
        "echo '$kafo_config_file=\"#{KafoConfigure.config_file}\" #{@command}'",
        " | ",
        "puppet apply #{@options.join(' ')} #{@suffix}"
    ].join
    @logger.debug result
    result
  end

  def append(suffix)
    @suffix = suffix
    self
  end

  private

  def modules_path
    [
        KafoConfigure.config.app[:puppet_modules_dir],
        File.join(File.dirname(__FILE__), '../../modules')
    ].join(':')
  end
end
