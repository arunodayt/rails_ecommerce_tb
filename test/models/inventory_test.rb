require "test_helper"

class InventoryTest < ActiveSupport::TestCase
  setup do
    @widget = products(:widget)   # stock 10
    @gadget = products(:gadget)   # stock 5
  end

  def item(product, quantity)
    OrderItem.new(product: product, quantity: quantity)
  end

  test "deduct! decrements stock" do
    Inventory.deduct!([item(@widget, 3)])
    assert_equal 7, inventories(:widget_stock).reload.quantity
  end

  test "restock! increments stock" do
    Inventory.restock!([item(@widget, 3)])
    assert_equal 13, inventories(:widget_stock).reload.quantity
  end

  test "deduct! raises when stock is insufficient" do
    error = assert_raises(Inventory::InsufficientStock) do
      Inventory.deduct!([item(@widget, 11)])
    end
    assert_match @widget.sku, error.message
    assert_equal 10, inventories(:widget_stock).reload.quantity
  end

  test "a product with no inventory row is treated as zero stock" do
    inventories(:gadget_stock).destroy!
    assert_raises(Inventory::InsufficientStock) do
      Inventory.deduct!([item(@gadget, 1)])
    end
  end

  test "restock! creates the inventory row when missing" do
    inventories(:gadget_stock).destroy!
    Inventory.restock!([item(@gadget, 3)])
    assert_equal 3, @gadget.reload.inventory.quantity
  end

  test "a multi-item deduction is all-or-nothing inside a transaction" do
    assert_raises(Inventory::InsufficientStock) do
      ApplicationRecord.transaction(requires_new: true) do
        Inventory.deduct!([item(@widget, 2), item(@gadget, 99)])
      end
    end
    assert_equal 10, inventories(:widget_stock).reload.quantity
    assert_equal 5, inventories(:gadget_stock).reload.quantity
  end

  test "quantity cannot be negative" do
    inventory = inventories(:widget_stock)
    inventory.quantity = -1
    assert_not inventory.valid?
  end
end
