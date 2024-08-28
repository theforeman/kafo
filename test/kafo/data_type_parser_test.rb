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

    describe "parse pattern with a hash inside" do
      let (:file) do
        <<~'PUPPET'
        type Stdlib::Email = Pattern[/\A[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\z/]
        PUPPET
      end
      it { _(parser.types).must_equal({"Stdlib::Email"=>"Pattern[/\\A[a-zA-Z0-9.!\#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\\z/]"}) }
    end

    describe "parse multiline alias" do
      let(:file) { "type IP = Variant[\n  IPv4,\n  IPv6,\n]" }
      it { _(parser.types).must_equal({'IP' => 'Variant[IPv4,IPv6,]'}) }
    end

    describe "parse multiline alias with EOL comment" do
      let(:file) { "type IP = Variant[\n  IPv4, # Legacy IP\n  IPv6,\n]" }
      it { _(parser.types).must_equal({'IP' => 'Variant[IPv4,IPv6,]'}) }
    end

    describe "parse multiple multiline aliases" do
      let(:file) { "# We need IP\ntype IP = Variant[\n  IPv4, # Legacy IP\n  IPv6,\n]\n# We also need IPProto\ntype IPProto = Variant[\n  TCP,\n  UDP,\n]" }
      it { _(parser.types).must_equal({"IP"=>"Variant[IPv4,IPv6,]", "IPProto"=>"Variant[TCP,UDP,]"}) }
    end

    describe "parse multiple multiline aliases with empty lines" do
      let(:file) { "# We need IP\n  \ntype IP = Variant[\n\n  IPv4, # Legacy IP\n\n  IPv6,\n\n]\n\n# We also need IPProto\n\ntype IPProto = Variant[\n\n  TCP,\n\n  UDP,\n\n]" }
      it { _(parser.types).must_equal({"IP"=>"Variant[IPv4,IPv6,]", "IPProto"=>"Variant[TCP,UDP,]"}) }
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
