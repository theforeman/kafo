# encoding: UTF-8
class PuppetCommand
  def initialize(command, options = [])
    @command = command
    @options = options.push("--modulepath #{modules_path}")
    @logger  = Logging.logger.root
  end

  def command
    custom_answer_file = if KafoConfigure.temp_config_file.nil?
      ''
    else
      "$kafo_answer_file=\"#{KafoConfigure.temp_config_file}\""
    end

    result = [
        "echo '$kafo_config_file=\"#{KafoConfigure.config_file}\" #{custom_answer_file} #{@command}'",
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
        KafoConfigure.config.app[:installer_dir] + '/modules',
        File.join(KafoConfigure.gem_root, 'modules')
    ].join(':')
  end
end
