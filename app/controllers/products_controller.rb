class ProductsController < ApplicationController
  include Authenticatable

  after_action :verify_policy_scoped, only: :index

  # GET /products
  def index
    authorize Product, :index?
    products = policy_scope(Product).order(:id)
    render json: products.map { |p| product_json(p) }
  end

  # GET /products/:id
  def show
    product = Product.find(params[:id])
    authorize product
    render json: product_json(product)
  end

  # POST /products
  def create
    product = Product.new
    authorize product
    product.assign_attributes(permitted_attributes(product))

    if product.save
      render json: product_json(product), status: :created
    else
      render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /products/:id
  def update
    product = Product.find(params[:id])
    authorize product

    if product.update(permitted_attributes(product))
      render json: product_json(product)
    else
      render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /products/:id
  def destroy
    product = Product.find(params[:id])
    authorize product
    product.destroy
    head :no_content
  end

  private

  def product_json(product)
    {
      id:          product.id,
      sku:         product.sku,
      name:        product.name,
      description: product.description,
      price_cents: product.price_cents,
      active:      product.active
    }
  end
end
