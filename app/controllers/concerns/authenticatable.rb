# Include in controllers that require a valid access token.
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    payload = JsonWebToken.decode(bearer_token, expected_type: "access")

    # The session must still be active - this enables instant logout.
    @current_session = Session.active.find_by(id: payload[:sid], user_id: payload[:sub])
    @current_user = @current_session&.user

    render_unauthorized("Invalid or revoked token") unless @current_user
  rescue JsonWebToken::DecodeError => e
    render_unauthorized(e.message)
  end

  def current_user
    @current_user
  end

  def current_session
    @current_session
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    header.start_with?("Bearer ") ? header.split(" ", 2).last : nil
  end

  def render_unauthorized(message = "Unauthorized")
    render json: { error: message }, status: :unauthorized
  end
end
