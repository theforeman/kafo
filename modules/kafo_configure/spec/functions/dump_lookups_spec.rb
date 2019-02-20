require 'spec_helper'

describe 'dump_lookups' do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  it { is_expected.to run.with_params([]).and_return({}) }
  it { is_expected.to run.with_params(['my_module::param']).and_return({'my_module::param' => 'override'}) }
end
