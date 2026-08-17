# Mocked exchange rates (value of 1 unit in USD). Replace the body of
# .fetch_rate with a real external API client later - callers only depend
# on this interface.
module ExchangeRateProvider
  class UnknownCurrency < StandardError; end

  MOCK_USD_RATES = {
    "USD" => 1.0,
    "EUR" => 1.08,
    "GBP" => 1.27,
    "INR" => 0.0105,
    "JPY" => 0.0067
  }.freeze

  def self.fetch_rate(code)
    MOCK_USD_RATES.fetch(code.to_s.strip.upcase) do
      raise UnknownCurrency, "No exchange rate available for #{code}"
    end
  end
end
