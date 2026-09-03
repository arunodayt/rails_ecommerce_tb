class CustomersController < ApplicationController
  include Authenticatable

  after_action :verify_policy_scoped, only: :index

  # GET /customers
  def index
    authorize Customer, :index?
    customers = policy_scope(Customer).order(:id)
    render json: customers.map { |c| customer_json(c) }
  end

  # GET /customers/:id
  def show
    customer = Customer.find(params[:id])
    authorize customer
    render json: customer_json(customer)
  end

  # POST /customers
  def create
    customer = Customer.new
    authorize customer
    customer.assign_attributes(permitted_attributes(customer))

    if customer.save
      render json: customer_json(customer), status: :created
    else
      render json: { errors: customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /customers/:id
  def update
    customer = Customer.find(params[:id])
    authorize customer

    if customer.update(permitted_attributes(customer))
      render json: customer_json(customer)
    else
      render json: { errors: customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /customers/:id
  def destroy
    customer = Customer.find(params[:id])
    authorize customer

    if customer.destroy
      head :no_content
    else
      render json: { errors: customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def customer_json(customer)
    { id: customer.id, name: customer.name, email: customer.email }
  end
end
