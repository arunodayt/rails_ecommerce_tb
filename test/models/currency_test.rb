require "test_helper"

class CurrencyTest < ActiveSupport::TestCase
  test "code is normalized to uppercase" do
    currency = Currency.create!(code: " gbp ", name: "British Pound", usd_rate: 1.27)
    assert_equal "GBP", currency.code
  end

  test "code must be a 3-letter ISO code" do
    currency = Currency.new(code: "EURO", name: "Euro", usd_rate: 1.0)
    assert_not currency.valid?
    assert currency.errors[:code].any?
  end

  test "code is unique case-insensitively" do
    currency = Currency.new(code: "usd", name: "Dollar again", usd_rate: 1.0)
    assert_not currency.valid?
  end

  test "usd_rate must be positive" do
    currency = Currency.new(code: "ZZZ", name: "Zed", usd_rate: 0)
    assert_not currency.valid?
  end

  test "find_by_code is case-insensitive" do
    assert_equal currencies(:eur), Currency.find_by_code("eur")
    assert_nil Currency.find_by_code("XXX")
  end

  test "refresh_rate! pulls the rate from the provider" do
    eur = currencies(:eur)
    assert_equal 1.05, eur.usd_rate.to_f

    eur.refresh_rate!
    assert_equal ExchangeRateProvider::MOCK_USD_RATES["EUR"], eur.usd_rate.to_f
    assert_not_nil eur.rate_updated_at
  end

  test "refresh_rate! raises for currencies unknown to the provider" do
    unknown = Currency.create!(code: "ZWL", name: "Zimbabwe Dollar", usd_rate: 0.5)
    assert_raises(ExchangeRateProvider::UnknownCurrency) { unknown.refresh_rate! }
  end
end
