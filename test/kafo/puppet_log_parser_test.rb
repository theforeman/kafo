# encoding: UTF-8

require 'test_helper'

module Kafo
  describe PuppetLogParser do
    describe "#parse" do
      subject { PuppetLogParser.new }
      specify { _(subject.parse('Error: foo')).must_equal [:error, 'foo'] }
      specify { _(subject.parse('Err: foo')).must_equal [:error, 'foo'] }
      specify { _(subject.parse('Warning: foo')).must_equal [:warn, 'foo'] }
      specify { _(subject.parse('Notice: foo')).must_equal [:warn, 'foo'] }
      specify { _(subject.parse('Debug: foo')).must_equal [:debug, 'foo'] }
      specify { _(subject.parse('unknown foo')).must_equal [:info, 'unknown foo'] }
      specify do
        _(subject.parse('Debug: foo')).must_equal [:debug, 'foo']
        _(subject.parse('bar')).must_equal [:debug, 'bar']
      end
    end
  end
end
