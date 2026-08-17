require "test_helper"

class AddressTest < ActiveSupport::TestCase
  setup do
    @acme = customers(:acme)
  end

  test "requires kind, line1, city and country" do
    address = @acme.addresses.build
    assert_not address.valid?
    assert address.errors[:kind].any?
    assert address.errors[:line1].any?
    assert address.errors[:city].any?
    assert address.errors[:country].any?
  end

  test "rejects an unknown kind" do
    address = @acme.addresses.build(kind: "office", line1: "1 Main St", city: "Springfield", country: "US")
    assert_not address.valid?
  end

  test "a new default replaces the previous default of the same kind" do
    new_default = @acme.addresses.create!(kind: "billing", line1: "9 New HQ", city: "Chicago",
                                          country: "US", default: true)
    assert new_default.default?
    assert_not addresses(:acme_billing).reload.default?
    # the shipping default is untouched
    assert addresses(:acme_shipping).reload.default?
  end

  test "snapshot returns only the address fields" do
    snapshot = addresses(:acme_billing).snapshot
    assert_equal %w[city country line1 line2 postal_code state], snapshot.keys.sort
    assert_equal "1 Acme Way", snapshot["line1"]
  end

  test "default_billing_address prefers the default flag" do
    @acme.addresses.create!(kind: "billing", line1: "3 Side St", city: "Springfield", country: "US")
    assert_equal addresses(:acme_billing), @acme.default_billing_address
  end
end
