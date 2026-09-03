# Sends the order confirmation email. Enqueued by Order after the creating
# transaction commits.
class OrderCreatedEmailJob < ApplicationJob
  queue_as :mailer

  # The order may have been destroyed between enqueue and perform; there is
  # nothing to confirm in that case.
  discard_on ActiveJob::DeserializationError

  def perform(order)
    OrderMailer.created(order).deliver_now
  end
end
