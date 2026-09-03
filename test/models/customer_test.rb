require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  test "email is normalized to stripped lowercase" do
    customer = Customer.create!(name: "Trim Co", email: "  Mixed@Case.TEST  ")
    assert_equal "mixed@case.test", customer.email
  end

  test "email uniqueness is case-insensitive" do
    existing = customers(:acme)
    dup = Customer.new(name: "Dupe", email: existing.email.upcase)
    assert_not dup.valid?
    assert_includes dup.errors[:email], "has already been taken"
  end

  test "name and email are required" do
    customer = Customer.new
    assert_not customer.valid?
    assert_includes customer.errors[:name], "can't be blank"
    assert_includes customer.errors[:email], "can't be blank"
  end

  test "malformed emails are rejected" do
    assert_not Customer.new(name: "Bad", email: "not-an-email").valid?
  end

  test "find_by_email is case-insensitive" do
    assert_equal customers(:acme), Customer.find_by_email(customers(:acme).email.upcase)
  end
end
