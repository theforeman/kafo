require 'spec_helper'

describe 'kafo_configure::dump_lookups' do
  it { is_expected.to run.with_params([]).and_return({}) }
end
