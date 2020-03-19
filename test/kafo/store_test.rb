require 'test_helper'

module Kafo
  describe Store do
    let(:store) { Store.new() }

    describe 'init' do
      it 'initializes when no dir is set' do
        _(store.data).must_equal({})
      end

      it 'loads data when dir is set' do
        store = Store.new('./test/fixtures/store')
        _(store.get('one')).must_equal 'new one'
        _(store.get('two')).must_equal 'new two'
      end

      it 'loads data when single file is set' do
        store = Store.new('./test/fixtures/store/1st.yaml')
        _(store.get('one')).must_equal 'old one'
      end

      it 'raises an error when the path is invalid' do
        err = _(proc{ Store.new('some_dir') }).must_raise Errno::ENOENT
        _(err.message).must_match "No such file or directory"
      end
    end

    describe 'get' do
      it 'returns value for the key' do
        store.add( {'key1' => 'value1'} )
        _(store.get('key1')).must_equal 'value1'
      end

      it 'returns nil for non-existing key' do
        _(store.get('key1')).must_be_nil
      end
    end
  end
end
