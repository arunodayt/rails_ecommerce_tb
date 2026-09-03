class CurrentUserController < ApplicationController
  include Authenticatable

  skip_after_action :verify_authorized

  # GET /me
  def show
    render json: { id: current_user.id, username: current_user.username, role: current_user.role }, status: :ok
  end
end
