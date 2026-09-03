require "test_helper"

class PaymentsTest < ActionDispatch::IntegrationTest
  setup do
    @admin  = users(:admin)
    @member = users(:member)
    @order  = orders(:acme_order) # total 2000 cents
  end

  test "recording a payment requires authentication" do
    post order_payments_path(@order), params: { payment: { amount_cents: 1000 } }, as: :json
    assert_response :unauthorized
  end

  test "a member can record a payment which defaults to USD" do
    assert_difference -> { @order.payments.count }, 1 do
      post order_payments_path(@order),
           params: { payment: { amount_cents: 500, payment_method: "credit_card", reference: "TXN-1" } },
           headers: bearer(access_token_for(@member)), as: :json
    end
    assert_response :created

    body = response.parsed_body
    assert_equal "USD", body["currency_code"]
    assert_equal 1.0, body["exchange_rate"]
    assert_equal 500, body["amount_usd_cents"]
    assert_equal "TXN-1", body["reference"]
  end

  test "a payment in a foreign currency is converted and snapshotted" do
    post order_payments_path(@order),
         params: { payment: { amount_cents: 10_000, currency_code: "eur", payment_method: "netbanking" } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :created

    body = response.parsed_body
    assert_equal "EUR", body["currency_code"]
    assert_equal 1.05, body["exchange_rate"]
    assert_equal 10_500, body["amount_usd_cents"]
  end

  test "an unknown currency is rejected" do
    post order_payments_path(@order),
         params: { payment: { amount_cents: 1000, currency_code: "XYZ", payment_method: "credit_card" } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :unprocessable_entity
  end

  test "an invalid payment method is rejected" do
    post order_payments_path(@order),
         params: { payment: { amount_cents: 1000, payment_method: "cheque" } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :unprocessable_entity
  end

  test "the order is marked paid once payments cover the total" do
    post order_payments_path(@order),
         params: { payment: { amount_cents: 2000, payment_method: "credit_card" } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :created
    assert_equal "paid", @order.reload.status
  end

  test "payments can be listed and shown for an order" do
    payment = Payment.create!(order: @order, amount_cents: 700, payment_method: "netbanking")

    get order_payments_path(@order), headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal [payment.id], response.parsed_body.map { |p| p["id"] }

    get order_payment_path(@order, payment), headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal 700, response.parsed_body["amount_cents"]
  end
end
