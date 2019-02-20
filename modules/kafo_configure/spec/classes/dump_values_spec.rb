require 'spec_helper'

describe 'kafo_configure::dump_values' do
  context 'without parameters' do
    it { is_expected.to compile.with_all_deps }
  end
end
