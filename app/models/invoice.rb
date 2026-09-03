class Invoice < ApplicationRecord
  belongs_to :order
  has_many :invoice_line_items, dependent: :destroy

  enum :status, { issued: "issued", void: "void" }, default: "issued", validate: true

  validates :tax_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :subtotal_cents, :tax_cents, :total_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :order_id, uniqueness: { conditions: -> { issued },
                                     message: "already has an issued invoice" },
                       if: :issued?
  validate :void_is_final, on: :update

  before_validation :compute_totals, on: :create

  # Issues an invoice for the order, snapshotting line items, billing address
  # and merchant details so later edits never change an issued invoice.
  # tax_rate is a percentage (18 means 18%).
  def self.generate_for!(order, tax_rate:)
    merchant = Rails.application.config.x.merchant

    transaction do
      invoice = create!(
        order: order,
        tax_rate: tax_rate,
        issued_at: Time.current,
        billing_name: order.customer.name,
        billing_address: order.customer.default_billing_address&.snapshot,
        merchant_name: merchant[:name],
        merchant_address: merchant[:address]
      )

      order.order_items.each do |item|
        invoice.invoice_line_items.create!(
          product_sku: item.product.sku,
          name: item.product.name,
          quantity: item.quantity,
          unit_price_cents: item.unit_price_cents
        )
      end

      invoice.update_column(:number, format("INV-%04d-%06d", invoice.issued_at.year, invoice.id))
      invoice
    end
  end

  private

  def compute_totals
    self.subtotal_cents ||= order&.total_cents
    return if tax_rate.blank? || subtotal_cents.blank?

    self.tax_cents = (subtotal_cents * tax_rate.to_d / 100).round
    self.total_cents = subtotal_cents + tax_cents
  end

  def void_is_final
    errors.add(:status, "cannot change once void") if status_changed? && status_was == "void"
  end
end
