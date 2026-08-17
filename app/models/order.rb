class Order < ApplicationRecord
  belongs_to :customer

  has_many :order_items, dependent: :destroy
  has_many :payments, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error
  accepts_nested_attributes_for :order_items

  enum :status,
       { pending: "pending", paid: "paid", shipped: "shipped", cancelled: "cancelled", refunded: "refunded" },
       default: "pending",
       validate: true

  validates :order_items, presence: true

  before_validation :recalculate_total
  after_create :deduct_inventory, unless: :cancelled?
  after_update :sync_inventory_with_status, if: :saved_change_to_status?
  # prepend so stock is returned before dependent order_items are destroyed
  before_destroy :restock_inventory, prepend: true, unless: :cancelled?

  private

  def recalculate_total
    live_items = order_items.reject(&:marked_for_destruction?)
    live_items.each(&:snapshot_unit_price)
    self.total_cents = live_items.sum(&:subtotal_cents)
  end

  def deduct_inventory
    Inventory.deduct!(order_items)
  end

  def restock_inventory
    Inventory.restock!(order_items)
  end

  def sync_inventory_with_status
    from, to = saved_change_to_status
    if to == "cancelled"
      Inventory.restock!(order_items)
    elsif from == "cancelled"
      Inventory.deduct!(order_items)
    end
  end
end
