require 'test_helper'

module Kafo
  describe SystemChecker do

    it "returns true if all checks pass" do
      KafoConfigure.stub(:check_dirs, ['./test/fixtures/checks/pass']) do
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
