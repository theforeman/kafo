require 'spec_helper'

describe 'dump_values' do
  it { is_expected.to run.with_params([]).and_return({}) }

  context 'with values' do
    let(:pre_condition) { 'include dummy' }
    it { is_expected.to run.with_params(['dummy::first']).and_return({'dummy::first' => 'foo'}) }
  end
end
