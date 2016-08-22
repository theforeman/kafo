require 'test_helper'
require 'kafo/parser_cache_writer'

module Kafo
  describe ParserCacheReader do
    subject { ParserCacheReader }

    describe ".new_from_file" do
      let(:valid_cache) do
        {:version => 1, :files => {}}
      end

      specify { subject.new_from_file(nil).must_be_nil }
      specify { subject.new_from_file('').must_be_nil }
      specify { subject.new_from_file('/non/existent/file').must_be_nil }
      specify { subject.new_from_file(['/non/existent/file']).must_be_nil }
      specify { subject.new_from_file(['/another/non/existent/file', '/non/existent/file']).must_be_nil }

      describe "with empty file" do
        let(:cache) { ParserCacheFactory.build('') }
        let(:another_cache) { ParserCacheFactory.build('') }
        specify { subject.new_from_file(cache.path).must_be_nil }
        specify { subject.new_from_file([cache.path, another_cache.path]).must_be_nil }
      end

      describe "with version other than 1" do
        let(:bad_version_cache) { ParserCacheFactory.build(valid_cache.update(:version => 2)) }
        let(:proper_cache) { ParserCacheFactory.build(valid_cache) }
        specify { subject.new_from_file([bad_version_cache.path, proper_cache.path]).must_be_nil }
      end

      describe "with missing files section" do
        let(:bad_cache) { ParserCacheFactory.build(valid_cache.reject { |k,v| k == :files }) }
        let(:proper_cache) { ParserCacheFactory.build(valid_cache) }
        specify { subject.new_from_file([bad_cache.path, proper_cache.path]).must_be_nil }
      end

      describe "with correct format" do
        let(:cache1) { ParserCacheFactory.build(valid_cache) }
        let(:cache2) { ParserCacheFactory.build(valid_cache) }
        specify { subject.new_from_file([cache1.path, cache2.path]).must_be_instance_of subject }
      end
    end

    describe "#get" do
      specify { subject.new({:files => {}}).get('test', '/test/file.pp').must_be_nil }
      specify { subject.new({:files => {'test' => {:data => {:parameters => []}}}}).get('test', '/test/file.pp').must_equal(:parameters => []) }
      specify { File.stub(:mtime, 1) { subject.new({:files => {'test' => {:mtime => 1, :data => :test}}}).get('test', '/test/file.pp').must_equal(:test) } }
      specify { File.stub(:mtime, 2) { subject.new({:files => {'test' => {:mtime => 1, :data => :test}}}).get('test', '/test/file.pp').must_be_nil } }
    end

    describe "compatibility with writer" do
      before do
        KafoConfigure.config = Configuration.new(ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path)
      end

      let(:parser) { TestParser.new(BASIC_MANIFEST) }
      let(:mod) { PuppetModule.new('puppet', parser) }
      let(:writer) { ParserCacheWriter.write([mod]) }
      let(:cache) { ParserCacheFactory.build(writer) }

      specify { File.stub(:mtime, 1) { subject.new_from_file(cache.path).get('puppet', parser.manifest_file).must_equal mod.raw_data } }
    end
  end
end
