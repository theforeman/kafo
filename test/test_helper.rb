require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/mock'

require 'manifest_file_factory'
require 'config_file_factory'
require 'test_parser'
require 'kafo'

require 'ostruct'


BASIC_CONFIGURATION = <<EOS
:answer_file: test/fixtures/basic_answers.yaml
:installer_dir: .
:modules_dir: test/fixtures/modules

:no_prefix: false
:mapping: {}
:order:

:default_values_dir: /tmp

:dont_save_answers: true
:ignore_undocumented: true

:mapping: []
:password: secret
EOS

class Minitest::Spec
  before do
    KafoConfigure.config   = Configuration.new(ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path)
    KafoConfigure.root_dir = File.dirname(__FILE__)
    KafoConfigure.logger   = Logger.new
    KafoConfigure.modules_dir = 'test/fixtures/modules'
    Logger.loggers = []
  end
end

def must_exit_with_code(code, &block)
  begin
    block.call
  rescue SystemExit => e
    e.status.must_equal(code)
  end
end

def must_be_on_stdout(output, *args)
  output.rewind
  stdout = output.read
  args.each do |inclusion|
    stdout.must_include inclusion
  end
end
