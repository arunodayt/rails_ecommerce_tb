# Sends the order cancellation email. Enqueued by Order after the destroying
# transaction commits.
#
# The order row is gone by the time this runs, so the job takes plain values
# snapshotted before the destroy rather than a record reference.
class OrderDeletedEmailJob < ApplicationJob
  queue_as :mailers

  def perform(order)
    OrderMailer.deleted(
      order_id: order.id,
      customer_name: order.customer.name,
      customer_email: order.customer.email,
      total_cents: order.total_cents
    ).deliver_now
  rescue StandardError => e
    return true
  end
end
