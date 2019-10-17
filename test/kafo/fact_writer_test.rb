require 'test_helper'
require 'kafo/fact_writer'

module Kafo
  describe FactWriter do
    subject { FactWriter }

    describe '#write_facts' do
      let(:directory) { File.join(Dir.mktmpdir, 'facts') }
      let(:facts) { {} }
      before { subject.write_facts(facts, directory) }
      after { FileUtils.rm_f(directory) }

      specify { File.exist?(File.join(directory, 'kafo.yaml')).must_equal(true) }
      specify { File.read(File.join(directory, 'kafo.yaml')).must_equal("--- {}\n") }
      specify { File.exist?(File.join(directory, 'kafo.rb')).must_equal(true) }
      specify { File.read(File.join(directory, 'kafo.rb')).must_include('Facter.add(:kafo)') }
    end

    describe '#wrapper' do
      specify { subject.wrapper.must_equal("      require 'yaml'\n      Facter.add(:kafo) { setcode { YAML.load_file(File.join(__dir__, 'kafo.yaml')) } }\n") }
    end
  end
end
