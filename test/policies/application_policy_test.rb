require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  # Any policy that forgets to define an action inherits these and fails closed.
  test "the base policy denies every action by default" do
    policy = ApplicationPolicy.new(users(:admin), Object.new)

    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "the base scope resolves to nothing" do
    scope = ApplicationPolicy::Scope.new(users(:admin), User.all)
    assert_empty scope.resolve
  end
end
