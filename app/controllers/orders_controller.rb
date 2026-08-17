class OrdersController < ApplicationController
  include Authenticatable

  after_action :verify_policy_scoped, only: :index

  # GET /orders
  def index
    authorize Order, :index?
    orders = policy_scope(Order).includes(:order_items).order(:id)
    render json: orders.map { |o| order_json(o) }
  end

  # GET /orders/:id
  def show
    order = Order.includes(:order_items).find(params[:id])
    authorize order
    render json: order_json(order)
  end

  # POST /orders
  def create
    order = Order.new
    authorize order
    order.assign_attributes(permitted_attributes(order, :create))

    if order.save
      render json: order_json(order), status: :created
    else
      render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /orders/:id
  def update
    order = Order.find(params[:id])
    authorize order

    if order.update(permitted_attributes(order, :update))
      render json: order_json(order)
    else
      render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /orders/:id
  def destroy
    order = Order.find(params[:id])
    authorize order

    if order.destroy
      head :no_content
    else
      render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def order_json(order)
    {
      id:          order.id,
      customer_id: order.customer_id,
      status:      order.status,
      total_cents: order.total_cents,
      order_items: order.order_items.map { |item| order_item_json(item) }
    }
  end

  def order_item_json(item)
    {
      id:               item.id,
      product_id:       item.product_id,
      quantity:         item.quantity,
      unit_price_cents: item.unit_price_cents,
      subtotal_cents:   item.subtotal_cents
    }
  end
end
