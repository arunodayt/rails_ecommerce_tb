ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# The app runs Delayed Job in every environment (config/application.rb), so job
# tests have to opt into the Active Job test adapter explicitly.
class ActiveJob::TestCase
  include ActionMailer::TestHelper

  def queue_adapter_for_test
    ActiveJob::QueueAdapters::TestAdapter.new
  end
end

# Shared helpers for request/integration tests that need authenticated calls.
class ActionDispatch::IntegrationTest
  TEST_PASSWORD = "password123".freeze

  # Logs a fixture user in and returns the parsed JSON token payload.
  def login(user, password: TEST_PASSWORD)
    post auth_login_path, params: { username: user.username, password: password }, as: :json
    response.parsed_body
  end

  def access_token_for(user, **opts)
    login(user, **opts).fetch("access_token")
  end

  # Authorization header hash for an access token.
  def bearer(token)
    { "Authorization" => "Bearer #{token}" }
  end
end
