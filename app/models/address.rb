class Address < ApplicationRecord
  belongs_to :customer

  enum :kind, { billing: "billing", shipping: "shipping" }, validate: true

  validates :line1, :city, :country, presence: true

  after_save :unset_other_defaults, if: :default?

  # Field snapshot for embedding into invoices.
  def snapshot
    slice(:line1, :line2, :city, :state, :postal_code, :country)
  end

  private

  def unset_other_defaults
    customer.addresses.where(kind: kind, default: true).where.not(id: id).update_all(default: false)
  end
end
