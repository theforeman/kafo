require 'test_helper'

module Kafo
  describe ExecutionEnvironment do
    let(:config_file) { ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path }
    let(:config) { Kafo::Configuration.new(config_file, false) }
    let(:execution_environment) { ExecutionEnvironment.new(config) }

    after { FileUtils.rm_rf(execution_environment.directory) }

    describe '#directory' do
      specify { assert File.directory?(execution_environment.directory) }
      specify { refute File.exist?(File.join(execution_environment.directory, 'hiera.conf')) }
    end

    describe '#configure_puppet' do
      let(:puppet_configurer) { execution_environment.configure_puppet }
      let(:directory) { execution_environment.directory }
      specify { assert_equal(File.join(directory, 'puppet.conf'), puppet_configurer.config_path) }
      specify { assert_equal(File.join(directory, 'hiera.conf'), puppet_configurer['hiera_config']) }
      specify { assert_equal(File.join(directory, 'environments'), puppet_configurer['environmentpath']) }
    end
  end
end
