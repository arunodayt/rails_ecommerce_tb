class UsersController < ApplicationController
  include Authenticatable

  after_action :verify_policy_scoped, only: :index

  # GET /users
  def index
    authorize User, :index?
    users = policy_scope(User).order(:id)
    render json: users.map { |u| user_json(u) }
  end

  # GET /users/:id
  def show
    user = User.find(params[:id])
    authorize user
    render json: user_json(user)
  end

  # POST /users
  def create
    user = User.new
    authorize user
    user.assign_attributes(permitted_attributes(user))

    if user.save
      render json: user_json(user), status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/:id
  def update
    user = User.find(params[:id])
    authorize user

    if user.update(permitted_attributes(user))
      render json: user_json(user)
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    user = User.find(params[:id])
    authorize user
    user.destroy
    head :no_content
  end

  private

  def user_json(user)
    { id: user.id, username: user.username, role: user.role }
  end
end
