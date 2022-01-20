require 'spec_helper'

describe 'kafo_configure::dump_variables' do
  it { is_expected.to run.with_params([]).and_return({}) }

  context 'with values' do
    let(:pre_condition) { 'include dummy' }
    it { is_expected.to run.with_params(['dummy::first']).and_return({'dummy::first' => 'foo'}) }
    it { is_expected.to run.with_params(['dummy::password']).and_return({'dummy::password' => 'supersecret'}) }
  end
end
