# Customer-facing order notifications. Always delivered from a job
# (OrderCreatedEmailJob / OrderDeletedEmailJob), never inline from a request.
class OrderMailer < ApplicationMailer
  def created(order)
    @order    = order
    @customer = order.customer
    @items    = order.order_items.includes(:product)

    mail(to: @customer.email, subject: "Order ##{@order.id} confirmed")
  end

  # The order row no longer exists here, so the email is built from values
  # snapshotted before the record was destroyed.
  def deleted(order_id:, customer_name:, customer_email:, total_cents:)
    @order_id      = order_id
    @customer_name = customer_name
    @total_cents   = total_cents

    mail(to: customer_email, subject: "Order ##{@order_id} cancelled")
  end
end
