require "test_helper"

class OrderCreatedEmailJobTest < ActiveJob::TestCase
  setup do
    @customer = customers(:acme)
    @order    = Order.create!(customer: @customer,
                              order_items: [ OrderItem.new(product: products(:widget), quantity: 1) ])
  end

  test "delivers the confirmation email to the customer" do
    assert_emails 1 do
      OrderCreatedEmailJob.perform_now(@order)
    end

    assert_equal [ @customer.email ], ActionMailer::Base.deliveries.last.to
  end

  test "an order destroyed before the job runs is discarded, not retried" do
    serialized = OrderCreatedEmailJob.new(@order).serialize
    @order.destroy!

    assert_emails 0 do
      ActiveJob::Base.execute(serialized)
    end
  end
end
