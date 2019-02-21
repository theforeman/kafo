require 'spec_helper'

describe 'kafo_configure' do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  let(:facts) { { puppetversion: Puppet.version } }

  context 'without parameters' do
    let(:params) { {add_progress: false} }
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('dummy') }
  end

  context 'with progress' do
    let(:params) { {add_progress: true} }
    it { is_expected.to compile.with_all_deps }
  end
end
