require 'test_helper'

module Kafo
  describe HieraConfigurer do
    subject { HieraConfigurer }

    describe "#generate_data" do
      let(:puppet_module) { @@puppet_module ||= PuppetModule.new('testing', TestParser.new(BASIC_MANIFEST)).tap { |m| m.enable }.parse }
      specify { _(puppet_module.enabled?).must_equal true }
      specify { _(subject.generate_data([puppet_module])['classes']).must_equal ['testing'] }
      specify { _(subject.generate_data([puppet_module])['testing::version']).must_equal '1.0' }
      specify { _(subject.generate_data([puppet_module]).size).must_equal (puppet_module.params.size + 1) }

      describe 'with order' do
        specify { _(subject.generate_data([puppet_module], ['testing', 'example'])['classes']).must_equal ['testing'] }
      end
    end

    describe "#sort_modules" do
      specify { _(subject.sort_modules(['a', 'b'], ['b', 'a'])).must_equal ['b', 'a'] }
      specify { _(subject.sort_modules(['a', 'b', 'extra'], ['b', 'a'])).must_equal ['b', 'a', 'extra'] }
      specify { _(subject.sort_modules(['a', 'b'], ['b', 'a', 'unused'])).must_equal ['b', 'a'] }
    end
  end
end
