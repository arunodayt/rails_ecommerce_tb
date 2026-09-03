class Inventory < ApplicationRecord
  class InsufficientStock < StandardError
  end

  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.deduct!(items)  = adjust!(items, -1)
  def self.restock!(items) = adjust!(items, 1)

  # Locks rows in product_id order so concurrent orders can't deadlock or
  # oversell. Must be called inside a transaction.
  def self.adjust!(items, sign)
    items.sort_by(&:product_id).each do |item|
      inventory = lock.find_or_initialize_by(product_id: item.product_id)
      new_quantity = inventory.quantity.to_i + sign * item.quantity

      raise InsufficientStock, "Insufficient inventory for #{item.product.sku}" if new_quantity.negative?

      inventory.quantity = new_quantity
      inventory.save!
    end
  end
end
