require "test_helper"

class AddressesTest < ActionDispatch::IntegrationTest
  setup do
    @admin   = users(:admin)
    @member  = users(:member)
    @acme    = customers(:acme)
    @billing = addresses(:acme_billing)
  end

  test "listing addresses requires authentication" do
    get customer_addresses_path(@acme)
    assert_response :unauthorized
  end

  test "a member can list a customer's addresses" do
    get customer_addresses_path(@acme), headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal 2, response.parsed_body.size
  end

  test "a member can add an address" do
    assert_difference -> { @acme.addresses.count }, 1 do
      post customer_addresses_path(@acme),
           params: { address: { kind: "shipping", line1: "5 Warehouse Rd", city: "Peoria",
                                state: "IL", postal_code: "61601", country: "US" } },
           headers: bearer(access_token_for(@member)), as: :json
    end
    assert_response :created
    assert_equal "shipping", response.parsed_body["kind"]
  end

  test "an incomplete address is rejected" do
    post customer_addresses_path(@acme),
         params: { address: { kind: "billing", line1: "" } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :unprocessable_entity
  end

  test "a member cannot update or delete an address" do
    patch customer_address_path(@acme, @billing),
          params: { address: { line1: "Changed" } },
          headers: bearer(access_token_for(@member)), as: :json
    assert_response :forbidden

    delete customer_address_path(@acme, @billing), headers: bearer(access_token_for(@member))
    assert_response :forbidden
  end

  test "an admin can update and delete an address" do
    patch customer_address_path(@acme, @billing),
          params: { address: { line1: "1 Renamed Way" } },
          headers: bearer(access_token_for(@admin)), as: :json
    assert_response :ok
    assert_equal "1 Renamed Way", @billing.reload.line1

    assert_difference -> { @acme.addresses.count }, -1 do
      delete customer_address_path(@acme, @billing), headers: bearer(access_token_for(@admin))
    end
    assert_response :no_content
  end

  test "addresses are scoped to the customer in the path" do
    get customer_address_path(customers(:globex), @billing), headers: bearer(access_token_for(@member))
    assert_response :not_found
  end
end
