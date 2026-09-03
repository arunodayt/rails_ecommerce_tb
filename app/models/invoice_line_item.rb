class InvoiceLineItem < ApplicationRecord
  belongs_to :invoice

  validates :product_sku, :name, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def subtotal_cents
    quantity * unit_price_cents
  end
end
