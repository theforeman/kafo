require 'test_helper'

module Kafo
  describe DataTypeParser do
    let(:parser) { DataTypeParser.new(file) }

    describe "parse basic alias" do
      let(:file) { 'type Test = String' }
      it { _(parser.types).must_equal({'Test' => 'String'}) }
    end

    describe "parse alias with comments" do
      let(:file) { "# Test alias\ntype Test = String\n" }
      it { _(parser.types).must_equal({'Test' => 'String'}) }
    end

    describe "parse alias with EOL comment" do
      let(:file) { 'type Test = String # Test alias' }
      it { _(parser.types).must_equal({'Test' => 'String'}) }
    end

    describe "parse complex alias" do
      let(:file) { 'type Ipv4 = Pattern[/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/]' }
      it { _(parser.types).must_equal({'Ipv4' => 'Pattern[/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/]'}) }
    end

    describe "#register" do
      after { DataType.unregister_type('Test') }
      let(:file) { 'type Test = String' }

      it do
        parser.register
        _(DataType.types).must_include 'Test'
      end
    end
  end
end
