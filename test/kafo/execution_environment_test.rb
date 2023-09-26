require 'test_helper'

module Kafo
  describe ExecutionEnvironment do
    let(:config_file) { ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path }
    let(:config) { Kafo::Configuration.new(config_file, false) }
    let(:execution_environment) { ExecutionEnvironment.new(config) }
    let(:directory) { execution_environment.directory }

    after { FileUtils.rm_rf(execution_environment.directory) }

    describe '#directory' do
      specify { assert File.directory?(directory) }
      specify { refute File.exist?(File.join(directory, 'hiera.yaml')) }
    end

    describe '#configure_puppet' do
      let(:puppet_configurer) { execution_environment.configure_puppet }
      specify { assert_equal(File.join(directory, 'puppet.conf'), puppet_configurer.config_path) }
      specify { assert_equal(File.join(directory, 'hiera.yaml'), puppet_configurer['hiera_config']) }
      specify { assert File.file?(puppet_configurer['hiera_config']) }
      specify { assert_equal(File.join(directory, 'environments'), puppet_configurer['environmentpath']) }
      specify { assert_equal(File.join(directory, 'facts'), puppet_configurer['factpath']) }
      specify { assert File.directory?(puppet_configurer['factpath']) }

      it 'writes the correct facts' do
        execution_environment.configure_puppet
        facts = YAML.load_file(File.join(directory, 'facts', 'kafo.yaml'))
        refute config.scenario_id.empty?
        expected = {
          'scenario' => {
            'id' => config.scenario_id,
            'name' => 'Basic',
            'answer_file' => File.join(directory, 'answers.yaml'),
            'custom' => {},
          },
        }
        assert_equal(expected, facts)
      end
    end

    describe '#reports' do
      let(:reports) { execution_environment.reports }

      specify 'with an empty directory it returns no reports' do
        assert_equal(reports, [])
      end

      specify 'with multiple reports it lists them in order of creation' do
        hostname = 'host.example.com'
        hostname_dir = File.join(execution_environment.reportdir, hostname)
        FileUtils.mkdir_p(hostname_dir)

        # Create files with different timestamps
        oldest = File.join(hostname_dir, 'oldest.yaml')
        FileUtils.touch(oldest)
        sleep(0.01)
        newer = File.join(hostname_dir, 'newer.yaml')
        FileUtils.touch(newer)
        sleep(0.01)
        aaa_latest = File.join(hostname_dir, 'aaa_latest.yaml')
        FileUtils.touch(aaa_latest)

        assert_equal([oldest, newer, aaa_latest], reports)
      end
    end
  end
end
