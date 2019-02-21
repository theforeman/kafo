require 'spec_helper'

describe 'kafo_configure::dump_values' do
  context 'without parameters' do
    let(:params) do
      {
        variables: [],
        lookups: [],
      }
    end
    it { is_expected.to compile.with_all_deps }
  end

  context 'with values' do
    let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
    let(:params) do
      {
        variables: ['dummy:first', 'dummy::second'],
        lookups: ['my_module::param'],
      }
    end
    it { is_expected.to compile.with_all_deps }
  end
end
