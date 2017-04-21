# encoding: UTF-8

require 'test_helper'

module Kafo
  describe PuppetLogParser do
    describe "#parse" do
      subject { PuppetLogParser.new }
      specify { subject.parse('Error: foo').must_equal [:error, ' foo'] }
      specify { subject.parse('Err: foo').must_equal [:error, ' foo'] }
      specify { subject.parse('Warning: foo').must_equal [:warn, ' foo'] }
      specify { subject.parse('Notice: foo').must_equal [:warn, ' foo'] }
      specify { subject.parse('Debug: foo').must_equal [:debug, ' foo'] }
      specify { subject.parse('unknown foo').must_equal [:info, 'unknown foo'] }
      specify do
        subject.parse('Debug: foo').must_equal [:debug, ' foo']
        subject.parse('bar').must_equal [:debug, 'bar']
      end
      specify { subject.parse("Error: invalid \255 byte").must_equal [:error, RUBY_VERSION.start_with?('1.8') ? " invalid \255 byte" : ' invalid ? byte'] }
    end
  end
end
