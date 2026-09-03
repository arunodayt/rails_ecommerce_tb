class TestJob < ApplicationJob
  queue_as :default

  # Simple test job to verify Delayed Job is working.
  def perform(message = "Hello from TestJob")
    Rails.logger.info("[TestJob] running at #{Time.current.iso8601}: #{message}")
  end
end
