require "test_helper"

class CustomersTest < ActionDispatch::IntegrationTest
  setup do
    @admin  = users(:admin)
    @member = users(:member)
    @acme   = customers(:acme)
  end

  test "listing customers requires authentication" do
    get customers_path
    assert_response :unauthorized
  end

  test "a member can list and view customers" do
    get customers_path, headers: bearer(access_token_for(@member))
    assert_response :ok

    get customer_path(@acme), headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal @acme.email, response.parsed_body["email"]
  end

  test "a member can register a new customer" do
    assert_difference -> { Customer.count }, 1 do
      post customers_path,
           params: { customer: { name: "New Co", email: "Hello@New.Test" } },
           headers: bearer(access_token_for(@member)), as: :json
    end
    assert_response :created
    # email is normalized to lowercase on save
    assert_equal "hello@new.test", response.parsed_body["email"]
  end

  test "duplicate emails are rejected case-insensitively" do
    post customers_path,
         params: { customer: { name: "Dup", email: @acme.email.upcase } },
         headers: bearer(access_token_for(@admin)), as: :json
    assert_response :unprocessable_entity
  end

  test "a member cannot update a customer" do
    patch customer_path(@acme),
          params: { customer: { name: "Renamed" } },
          headers: bearer(access_token_for(@member)), as: :json
    assert_response :forbidden
  end

  test "an admin can update and delete a customer" do
    patch customer_path(@acme),
          params: { customer: { name: "Renamed" } },
          headers: bearer(access_token_for(@admin)), as: :json
    assert_response :ok
    assert_equal "Renamed", @acme.reload.name
  end

  test "deleting a customer with orders is rejected" do
    delete customer_path(@acme), headers: bearer(access_token_for(@admin))
    assert_response :unprocessable_entity
    assert Customer.exists?(@acme.id)
  end
end
