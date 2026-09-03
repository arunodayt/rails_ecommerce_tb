require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @customer = customers(:acme)
    @widget   = products(:widget)   # 1000 cents
    @gadget   = products(:gadget)   # 2500 cents
  end

  test "total_cents is computed from the line items on save" do
    order = Order.new(customer: @customer)
    order.order_items.build(product: @widget, quantity: 2)
    order.order_items.build(product: @gadget, quantity: 1)

    assert order.save
    assert_equal 2 * 1000 + 2500, order.total_cents
  end

  test "an order requires at least one line item" do
    order = Order.new(customer: @customer)
    assert_not order.valid?
    assert_includes order.errors[:order_items], "can't be blank"
  end

  test "line items snapshot the product price when none is given" do
    order = Order.create!(customer: @customer, order_items: [OrderItem.new(product: @widget, quantity: 1)])
    assert_equal @widget.price_cents, order.order_items.first.unit_price_cents
  end

  test "an explicitly provided unit price is preserved" do
    item  = OrderItem.new(product: @widget, quantity: 1, unit_price_cents: 777)
    order = Order.create!(customer: @customer, order_items: [item])
    assert_equal 777, order.order_items.first.unit_price_cents
  end

  test "changing the product price later does not rewrite existing orders" do
    order = Order.create!(customer: @customer, order_items: [OrderItem.new(product: @widget, quantity: 1)])
    original = order.total_cents

    @widget.update!(price_cents: 9999)

    assert_equal original, order.reload.total_cents
  end

  test "quantity must be positive" do
    order = Order.new(customer: @customer, order_items: [OrderItem.new(product: @widget, quantity: 0)])
    assert_not order.valid?
  end
end
