require 'test_helper'

module Kafo
  describe SystemChecker do
    PATH = './test/fixtures/checks/pass'

    it "returns loads checks in order" do
      KafoConfigure.stub(:check_dirs, [PATH]) do
        expected = ["./test/fixtures/checks/pass/pass.sh", "./test/fixtures/checks/pass/this_also_passes.sh"]
        assert_equal expected, SystemChecker.new(File.join(PATH, '*')).checkers
      end
    end

    it "returns true if all checks pass" do
      KafoConfigure.stub(:check_dirs, [PATH]) do
        assert SystemChecker.check
      end
    end

    it "returns false if any checks fail" do
      dirs = [
        './test/fixtures/checks/fail',
        './test/fixtures/checks/pass'
      ]

      KafoConfigure.stub(:check_dirs, dirs) do
        refute SystemChecker.check
      end
    end

  end
end
