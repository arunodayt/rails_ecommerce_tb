class Currency < ApplicationRecord
  before_validation :normalize_code

  validates :code, presence: true,
                   format: { with: /\A[A-Z]{3}\z/, message: "must be a 3-letter ISO code" },
                   uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :usd_rate, numericality: { greater_than: 0 }

  # Case-insensitive lookup
  def self.find_by_code(code)
    return nil if code.blank?

    where("upper(code) = ?", code.to_s.strip.upcase).first
  end

  def refresh_rate!
    update!(usd_rate: ExchangeRateProvider.fetch_rate(code), rate_updated_at: Time.current)
  end

  private

  def normalize_code
    self.code = code.to_s.strip.upcase if code.present?
  end
end
