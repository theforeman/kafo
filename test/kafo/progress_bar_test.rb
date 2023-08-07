require 'test_helper'

module Kafo
  describe ProgressBar do
    let(:bar) { ProgressBar.new.tap { |pb| pb.instance_variable_set(:@bar, powerbar) } }
    let(:powerbar) { Minitest::Mock.new }

    it "calls powerbar.show" do
      powerbar.expect(:show, nil, [{:msg => 'Notify[test]                                      ', :done => 0, :total => 2}, true])
      powerbar.expect(:show, nil, [{:msg => 'Prefetching example resources for example_type    ', :done => 1, :total => 2}, true])
      powerbar.expect(:show, nil, [{:msg => 'File[/foo/bar]                                    ', :done => 1, :total => 2}, true])

      bar.update('MONITOR_RESOURCE File[/foo/bar]')
      bar.update('MONITOR_RESOURCE Notify[test]')
      bar.update('/Stage[main]/Example/Notify[test]: Starting to evaluate the resource')
      bar.update('/Stage[main]/Example/Notify[test]: Evaluated in 0.5 seconds')
      bar.update('Prefetching example resources for example_type')
      bar.update('/Stage[main]/Example/File[/foo/bar]: Starting to evaluate the resource')
      bar.update('/Stage[main]/Example/File[/foo/bar]: Evaluated in 0.5 seconds')
      powerbar.verify
    end

    it 'handles an unknown total' do
      powerbar.expect(:show, nil, [{:msg => 'Prefetching example resources for example_type    ', :done => 0, :total => :unknown}, true])

      bar.update('/Stage[main]/Example/Notify[test]: Starting to evaluate the resource')
      bar.update('/Stage[main]/Example/Notify[test]: Evaluated in 0.5 seconds')
      bar.update('Prefetching example resources for example_type')
      bar.update('/Stage[main]/Example/File[/foo/bar]: Starting to evaluate the resource')
      bar.update('/Stage[main]/Example/File[/foo/bar]: Evaluated in 0.5 seconds')
      powerbar.verify
    end
  end
end
