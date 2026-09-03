class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :snapshot_unit_price, on: :create

  def subtotal_cents
    quantity.to_i * unit_price_cents.to_i
  end

  def snapshot_unit_price
    return if unit_price_cents.present? && unit_price_cents.positive?

    self.unit_price_cents = product&.price_cents
  end
end
