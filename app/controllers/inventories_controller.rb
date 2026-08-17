class InventoriesController < ApplicationController
  include Authenticatable

  before_action :set_product

  # GET /products/:product_id/inventory
  def show
    inventory = find_or_build_inventory
    authorize inventory
    render json: inventory_json(inventory)
  end

  # PATCH/PUT /products/:product_id/inventory
  def update
    inventory = find_or_build_inventory
    authorize inventory

    if inventory.update(permitted_attributes(inventory))
      render json: inventory_json(inventory)
    else
      render json: { errors: inventory.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def find_or_build_inventory
    @product.inventory || @product.build_inventory(quantity: 0)
  end

  def inventory_json(inventory)
    { product_id: @product.id, quantity: inventory.quantity }
  end
end
