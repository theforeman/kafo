require 'spec_helper'

describe 'kafo_configure::to_yaml' do
  it { is_expected.to run.with_params({}, {}).and_return("--- {}\n\n...\n") }
end
