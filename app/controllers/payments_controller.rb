class PaymentsController < ApplicationController
  include Authenticatable

  before_action :set_order
  after_action :verify_policy_scoped, only: :index

  # GET /orders/:order_id/payments
  def index
    authorize Payment, :index?
    payments = policy_scope(Payment).where(order: @order).order(:id)
    render json: payments.map { |p| payment_json(p) }
  end

  # GET /orders/:order_id/payments/:id
  def show
    payment = @order.payments.find(params[:id])
    authorize payment
    render json: payment_json(payment)
  end

  # POST /orders/:order_id/payments
  def create
    payment = @order.payments.build
    authorize payment
    payment.assign_attributes(permitted_attributes(payment))

    if payment.save
      render json: payment_json(payment), status: :created
    else
      render json: { errors: payment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def payment_json(payment)
    {
      id:               payment.id,
      order_id:         payment.order_id,
      amount_cents:     payment.amount_cents,
      currency_code:    payment.currency_code,
      exchange_rate:    payment.exchange_rate.to_f,
      amount_usd_cents: payment.amount_usd_cents,
      payment_method:   payment.payment_method,
      reference:        payment.reference,
      notes:            payment.notes,
      paid_at:          payment.paid_at
    }
  end
end
