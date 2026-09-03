class AuthController < ApplicationController
  include Authenticatable

  skip_after_action :verify_authorized
  skip_before_action :authenticate_user!, only: %i[login refresh]

  # POST /auth/login
  def login
    user = User.find_by_username(params[:username])

    if user&.authenticate(params[:password].to_s)
      session = Session.start!(user, user_agent: request.user_agent, ip_address: request.remote_ip)
      render json: token_payload(user, session), status: :ok
    else
      render json: { error: "Invalid username or password" }, status: :unauthorized
    end
  end

  # POST /auth/refresh
  def refresh
    payload = JsonWebToken.decode(params[:refresh_token].to_s, expected_type: "refresh")
    session = Session.active.find_by(id: payload[:sid], user_id: payload[:sub])

    return render json: { error: "Invalid refresh token" }, status: :unauthorized unless session

    if session.refresh_jti != payload[:jti]
      session.revoke!
      return render json: { error: "Refresh token already used" }, status: :unauthorized
    end

    session.rotate_refresh!
    render json: token_payload(session.user, session), status: :ok
  rescue JsonWebToken::DecodeError => e
    render json: { error: e.message }, status: :unauthorized
  end

  # DELETE /auth/logout
  def logout
    current_session.revoke!
    head :no_content
  end

  # DELETE /auth/logout_all — revokes every active session for the user.
  def logout_all
    current_user.sessions.active.find_each(&:revoke!)
    head :no_content
  end

  private

  def token_payload(user, session)
    session.token_response.merge(user: { id: user.id, username: user.username })
  end
end
