require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @order = orders(:acme_order) # total 2000 cents (USD)
  end

  def build_payment(**attrs)
    Payment.new(order: @order, amount_cents: 1000, payment_method: "credit_card", **attrs)
  end

  test "defaults to USD with a 1:1 conversion" do
    payment = build_payment
    assert payment.save
    assert_equal "USD", payment.currency_code
    assert_equal 1.0, payment.exchange_rate.to_f
    assert_equal 1000, payment.amount_usd_cents
    assert_not_nil payment.paid_at
  end

  test "converts to USD using the currency's stored rate" do
    payment = build_payment(amount_cents: 10_000, currency_code: "eur") # rate 1.05
    assert payment.save
    assert_equal "EUR", payment.currency_code
    assert_equal 10_500, payment.amount_usd_cents
  end

  test "rounds the converted amount" do
    payment = build_payment(amount_cents: 1500, currency_code: "INR") # rate 0.012
    assert payment.save
    assert_equal 18, payment.amount_usd_cents
  end

  test "snapshots the exchange rate at entry time" do
    payment = build_payment(amount_cents: 10_000, currency_code: "EUR")
    payment.save!

    currencies(:eur).update!(usd_rate: 2.0)
    assert_equal 1.05, payment.reload.exchange_rate.to_f
    assert_equal 10_500, payment.amount_usd_cents
  end

  test "rejects unknown currencies" do
    payment = build_payment(currency_code: "XYZ")
    assert_not payment.save
    assert payment.errors[:currency_code].any?
  end

  test "rejects a non-positive amount" do
    assert_not build_payment(amount_cents: 0).save
  end

  test "a partial payment leaves the order pending" do
    build_payment(amount_cents: 1000).save!
    assert_equal "pending", @order.reload.status
  end

  test "the order is marked paid once payments cover its total in USD" do
    build_payment(amount_cents: 1000).save!
    build_payment(amount_cents: 1000, currency_code: "EUR").save! # 1050 USD cents
    assert_equal "paid", @order.reload.status
  end

  test "payments do not regress an already shipped order" do
    @order.update!(status: "shipped")
    build_payment(amount_cents: 2000).save!
    assert_equal "shipped", @order.reload.status
  end
end
