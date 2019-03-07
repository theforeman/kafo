require 'test_helper'
require 'kafo/hiera_configurer'

module Kafo
  describe HieraConfigurer do
    subject { HieraConfigurer.new(user_config_path, [], modules_order) }
    let(:user_config_path) { nil }
    let(:modules_order) { nil }

    describe "#generate_config" do
      before { subject.build_temp_dir }
      after { FileUtils.rm_rf(subject.temp_dir) }

      let(:kafo_hierarchy) do
        {
          'name' => 'Kafo Answers',
          'path' => 'kafo_answers.yaml',
          'datadir' => File.join(subject.temp_dir, 'data'),
          'data_hash' => 'yaml_data',
        }
      end

      specify 'without an existing config' do
        subject.generate_config.must_equal({
          'version' => 5,
          'defaults' => {
            'datadir' => File.join(subject.temp_dir, 'data'),
            'data_hash' => 'yaml_data',
          },
          'hierarchy' => [kafo_hierarchy],
        })
      end

      describe 'context an existing config' do
        let(:user_config_path) { '/path/to/config/hiera.yaml' }

        specify 'with a data directory' do
          subject.generate_config('defaults' => {'datadir' => 'data'})['defaults']['datadir'].must_equal('/path/to/config/data')
        end

        specify 'with an empty hierarchy' do
          hierarchy = []
          expected = [kafo_hierarchy]
          subject.generate_config('hierarchy' => hierarchy)['hierarchy'].must_equal(expected)
        end

        specify 'with a kafo hierarchy' do
          hierarchy = [{'name' => 'Kafo Answers', 'datadir' => 'data'}]
          expected = [kafo_hierarchy]
          subject.generate_config('hierarchy' => hierarchy)['hierarchy'].must_equal(expected)
        end

        specify 'with a common hierarchy' do
          hierarchy = [{'name' => 'Common', 'datadir' => 'data'}]
          expected = [kafo_hierarchy, {'name' => 'Common', 'datadir' => '/path/to/config/data'}]
          subject.generate_config('hierarchy' => hierarchy)['hierarchy'].must_equal(expected)
        end

        specify 'with a common and kafo hierarchy' do
          hierarchy = [{'name' => 'Common'}, {'name' => 'Kafo Answers'}]
          expected = [{'name' => 'Common'}, kafo_hierarchy]
          subject.generate_config('hierarchy' => hierarchy)['hierarchy'].must_equal(expected)
        end
      end
    end

    describe "#generate_data" do
      let(:puppet_module) { @@puppet_module ||= PuppetModule.new('testing', TestParser.new(BASIC_MANIFEST)).tap { |m| m.enable }.parse }
      specify { puppet_module.enabled?.must_equal true }
      specify { subject.generate_data([puppet_module])['classes'].must_equal ['testing'] }
      specify { subject.generate_data([puppet_module])['testing::version'].must_equal '1.0' }
      specify { subject.generate_data([puppet_module]).size.must_equal (puppet_module.params.size + 1) }

      describe 'with order' do
        let(:modules_order) { ['testing', 'example'] }
        specify do
          subject.stub(:sort_modules, Proc.new { |modules, order|
            ['testing'] if modules == ['testing'] && order == modules_order
          }) { subject.generate_data([puppet_module])['classes'].must_equal ['testing'] }
        end
      end
    end

    describe "#write_configs" do
      subject { HieraConfigurer.new(nil, [], nil).tap { |s| s.write_configs } }
      after { FileUtils.rm_rf(subject.temp_dir) }
      specify { File.exist?(subject.config_path).must_equal true }
      specify { File.exist?(subject.data_dir).must_equal true }
      specify { File.exist?(File.join(subject.data_dir, 'kafo_answers.yaml')).must_equal true }
    end

    describe "#sort_modules" do
      specify { subject.sort_modules(['a', 'b'], ['b', 'a']).must_equal ['b', 'a'] }
      specify { subject.sort_modules(['a', 'b', 'extra'], ['b', 'a']).must_equal ['b', 'a', 'extra'] }
      specify { subject.sort_modules(['a', 'b'], ['b', 'a', 'unused']).must_equal ['b', 'a'] }
    end
  end
end
