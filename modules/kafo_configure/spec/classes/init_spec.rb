require 'spec_helper'

describe 'kafo_configure' do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  let(:facts) { { puppetversion: Puppet.version } }

  context 'without parameters' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('dummy') }
  end

  context 'with progress' do
    let(:params) { { add_progress: true } }
    it { is_expected.to compile.with_all_deps }
  end

  context 'with requirements' do
    context 'invalid' do
      let(:params) { { module_requirements: { ancient: '~> 1.0.0' } } }
      it { is_expected.to raise_error(/does not meet requirements for ancient \(~> 1\.0\.0\)/) }
    end

    context 'valid' do
      let(:params) { { module_requirements: { valid: '>= 4.5.0' } } }
      it { is_expected.to compile.with_all_deps }
    end
  end
end
