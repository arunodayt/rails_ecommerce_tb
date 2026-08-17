class AddressesController < ApplicationController
  include Authenticatable

  before_action :set_customer
  after_action :verify_policy_scoped, only: :index

  # GET /customers/:customer_id/addresses
  def index
    authorize Address, :index?
    addresses = policy_scope(Address).where(customer: @customer).order(:id)
    render json: addresses.map { |a| address_json(a) }
  end

  # GET /customers/:customer_id/addresses/:id
  def show
    address = @customer.addresses.find(params[:id])
    authorize address
    render json: address_json(address)
  end

  # POST /customers/:customer_id/addresses
  def create
    address = @customer.addresses.build
    authorize address
    address.assign_attributes(permitted_attributes(address))

    if address.save
      render json: address_json(address), status: :created
    else
      render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /customers/:customer_id/addresses/:id
  def update
    address = @customer.addresses.find(params[:id])
    authorize address

    if address.update(permitted_attributes(address))
      render json: address_json(address)
    else
      render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /customers/:customer_id/addresses/:id
  def destroy
    address = @customer.addresses.find(params[:id])
    authorize address
    address.destroy
    head :no_content
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def address_json(address)
    {
      id:          address.id,
      customer_id: address.customer_id,
      kind:        address.kind,
      line1:       address.line1,
      line2:       address.line2,
      city:        address.city,
      state:       address.state,
      postal_code: address.postal_code,
      country:     address.country,
      default:     address.default
    }
  end
end
