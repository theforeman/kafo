require 'test_helper'
require 'kafo/hiera_configurer'

module Kafo
  describe HieraConfigurer do
    subject { HieraConfigurer.new(nil, [], modules_order, module_dirs, puppet_version_check) }
    let(:modules_order) { nil }
    let(:module_dirs) { [] }
    let(:puppet_version_check) { true }

    describe "#generate_config" do
      specify { subject.generate_config[:backends].must_equal ['yaml'] }
      specify { subject.generate_config(:backends => ['json'])[:backends].must_equal ['json', 'yaml'] }
      specify { subject.generate_config[:hierarchy].must_equal ['kafo_answers'] }
      specify { subject.generate_config(:hierarchy => ['common'])[:hierarchy].must_equal ['kafo_answers', 'common'] }
      specify { subject.generate_config[:yaml].keys.must_include(:datadir) }
    end

    describe "#generate_data" do
      let(:puppet_module) { @@puppet_module ||= PuppetModule.new('testing', TestParser.new(BASIC_MANIFEST)).tap { |m| m.enable }.parse }
      specify { puppet_module.enabled?.must_equal true }
      specify { subject.generate_data([puppet_module])['classes'].must_equal ['testing'] }
      specify { subject.generate_data([puppet_module])['testing::version'].must_equal '1.0' }
      specify { subject.generate_data([puppet_module]).size.must_equal (puppet_module.params.size + 3) }

      specify 'must add progress' do
        subject.stub(:add_progress, true) { subject.generate_data([])['kafo_configure::add_progress'].must_equal true }
      end

      specify 'must add module requirements' do
        subject.stub(:module_requirements, {'puppetlabs-stdlib' => '>= 4.13.0 < 6.0.0'}) do
          subject.generate_data([])['kafo_configure::module_requirements'].must_equal({'puppetlabs-stdlib' => '>= 4.13.0 < 6.0.0'})
        end
      end

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
      subject { HieraConfigurer.new(nil, [], nil, [], true).tap { |s| s.write_configs } }
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

    describe "#module_requirements" do
      let(:module_dirs) { ['/modules'] }

      describe 'with puppet_version_check = true' do
        let(:puppet_version_check) { true }

        specify 'must generate module requirements' do
          Dir.stub(:[], ['./test/fixtures/metadata/basic.json']) do
            subject.module_requirements.must_equal({"theforeman-testing" => ">= 3.0.0 < 999.0.0"})
          end
        end
      end

      describe 'with puppet_version_check = false' do
        let(:puppet_version_check) { false }

        specify 'must generate empty module requirements' do
          Dir.stub(:[], ['./test/fixtures/metadata/basic.json']) do
            subject.module_requirements.must_equal({})
          end
        end
      end
    end

    describe '#add_progress' do
      specify { KafoConfigure.stub(:verbose, false) { subject.add_progress.must_equal true } }
      specify { KafoConfigure.stub(:verbose, true) { subject.add_progress.must_equal false } }
    end
  end
end
