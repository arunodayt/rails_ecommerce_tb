class Product < ApplicationRecord
  has_many :order_items, dependent: :restrict_with_error
  has_one :inventory, dependent: :destroy

  before_validation :normalize_sku

  validates :name, presence: true, length: { maximum: 100 }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sku, presence: true,
                  length: { maximum: 50 },
                  uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }

  private

  def normalize_sku
    self.sku = sku.to_s.strip.upcase if sku.present?
  end
end
