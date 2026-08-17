require "test_helper"

class CurrenciesTest < ActionDispatch::IntegrationTest
  setup do
    @admin  = users(:admin)
    @member = users(:member)
  end

  test "listing currencies requires authentication" do
    get currencies_path
    assert_response :unauthorized
  end

  test "any authenticated user can list and view currencies" do
    get currencies_path, headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal %w[EUR INR USD], response.parsed_body.map { |c| c["code"] }

    get currency_path("eur"), headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal 1.05, response.parsed_body["usd_rate"]
  end

  test "an unknown currency code returns 404" do
    get currency_path("XXX"), headers: bearer(access_token_for(@member))
    assert_response :not_found
  end

  test "a member cannot create a currency" do
    post currencies_path,
         params: { currency: { code: "GBP", name: "British Pound", usd_rate: 1.27 } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :forbidden
  end

  test "an admin can create and update a currency" do
    post currencies_path,
         params: { currency: { code: "gbp", name: "British Pound", usd_rate: 1.27 } },
         headers: bearer(access_token_for(@admin)), as: :json
    assert_response :created
    assert_equal "GBP", response.parsed_body["code"]

    patch currency_path("GBP"),
          params: { currency: { usd_rate: 1.30 } },
          headers: bearer(access_token_for(@admin)), as: :json
    assert_response :ok
    assert_equal 1.30, response.parsed_body["usd_rate"]
  end

  test "an admin can refresh a rate from the provider" do
    patch refresh_currency_path("EUR"), headers: bearer(access_token_for(@admin))
    assert_response :ok
    assert_equal 1.08, response.parsed_body["usd_rate"]
    assert_equal 1.08, currencies(:eur).reload.usd_rate.to_f
  end

  test "a member cannot refresh a rate" do
    patch refresh_currency_path("EUR"), headers: bearer(access_token_for(@member))
    assert_response :forbidden
  end
end
