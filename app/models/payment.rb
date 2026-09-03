class Payment < ApplicationRecord
  DEFAULT_CURRENCY = "USD".freeze

  belongs_to :order

  enum :payment_method, { credit_card: "credit_card", netbanking: "netbanking" }, validate: true

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validate :currency_must_exist

  before_validation :apply_defaults_and_convert, on: :create
  after_create :mark_order_paid

  private

  def apply_defaults_and_convert
    self.currency_code = currency_code.to_s.strip.upcase.presence || DEFAULT_CURRENCY
    self.paid_at ||= Time.current

    return unless (currency = Currency.find_by_code(currency_code))

    # Snapshot the rate so the USD amount stays auditable after rates change.
    self.exchange_rate = currency.usd_rate
    self.amount_usd_cents = (amount_cents.to_i * exchange_rate).round
  end

  def currency_must_exist
    errors.add(:currency_code, "is not a known currency") unless Currency.find_by_code(currency_code)
  end

  def mark_order_paid
    return unless order.pending?
    return if order.payments.sum(:amount_usd_cents) < order.total_cents

    order.update!(status: "paid")
  end
end
