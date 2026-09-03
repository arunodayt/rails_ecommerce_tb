require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  setup do
    @customer = customers(:acme)
    @widget   = products(:widget)   # 1000 cents
    @order    = Order.create!(customer: @customer,
                              order_items: [ OrderItem.new(product: @widget, quantity: 2) ])
  end

  test "created is addressed to the customer and lists the order" do
    mail = OrderMailer.created(@order)

    assert_equal [ @customer.email ], mail.to
    assert_equal "Order ##{@order.id} confirmed", mail.subject
    assert_match @customer.name, mail.body.encoded
    assert_match @widget.sku, mail.body.encoded
    assert_match "$20.00", mail.body.encoded
  end
end
