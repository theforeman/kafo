require 'spec_helper'

describe 'kafo_configure' do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

  context 'without parameters' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('dummy') }
  end
end
