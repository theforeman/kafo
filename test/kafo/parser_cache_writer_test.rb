require 'test_helper'
require 'kafo/parser_cache_writer'
require 'tempfile'

module Kafo
  describe ParserCacheWriter do
    subject { ParserCacheWriter }

    describe ".write" do
      specify { _(subject.write([])[:version]).must_equal 1 }
      specify { _(subject.write([])[:files]).must_equal({}) }

      describe "with a module" do
        let(:manifest) { Tempfile.new("#{subject}_manifest") }
        let(:mod) do
          mod = Minitest::Mock.new
          mod.expect(:identifier, 'module')
          mod.expect(:manifest_path, manifest.path)
          mod.expect(:raw_data, {:parameters => [], :groups => []})
          mod
        end
        let(:output) { subject.write([mod]) }

        specify { _(output[:files].keys).must_equal ['module'] }
        specify { output[:files]['module'].keys.each { |k| _(k).must_be_kind_of(Symbol) } }
        specify { _(output[:files]['module'].keys.map(&:to_s).sort).must_equal ['data', 'mtime'] }
        specify { _(output[:files]['module'][:mtime]).must_equal File.mtime(manifest.path).to_i }
        specify { _(output[:files]['module'][:data].has_key?(:parameters)).must_equal true }
        specify { _(output[:files]['module'][:data][:parameters]).must_equal([]) }
      end
    end
  end
end
