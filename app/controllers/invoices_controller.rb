class InvoicesController < ApplicationController
  include Authenticatable

  after_action :verify_policy_scoped, only: :index

  # GET /invoices
  def index
    authorize Invoice, :index?
    invoices = policy_scope(Invoice).includes(:invoice_line_items).order(:id)
    render json: invoices.map { |i| invoice_json(i) }
  end

  # GET /invoices/:id
  def show
    invoice = Invoice.includes(:invoice_line_items).find(params[:id])
    authorize invoice
    render json: invoice_json(invoice)
  end

  # POST /orders/:order_id/invoices
  def create
    order = Order.find(params[:order_id])
    authorize Invoice.new(order: order)

    tax_rate = permitted_attributes(Invoice.new, :create)[:tax_rate]
    invoice = Invoice.generate_for!(order, tax_rate: tax_rate)
    render json: invoice_json(invoice), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # PATCH/PUT /invoices/:id - only used to void an invoice
  def update
    invoice = Invoice.find(params[:id])
    authorize invoice

    if invoice.update(permitted_attributes(invoice, :update))
      render json: invoice_json(invoice)
    else
      render json: { errors: invoice.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def invoice_json(invoice)
    {
      id:               invoice.id,
      order_id:         invoice.order_id,
      number:           invoice.number,
      status:           invoice.status,
      tax_rate:         invoice.tax_rate.to_f,
      subtotal_cents:   invoice.subtotal_cents,
      tax_cents:        invoice.tax_cents,
      total_cents:      invoice.total_cents,
      issued_at:        invoice.issued_at,
      billing_name:     invoice.billing_name,
      billing_address:  invoice.billing_address,
      merchant_name:    invoice.merchant_name,
      merchant_address: invoice.merchant_address,
      line_items:       invoice.invoice_line_items.map { |item| line_item_json(item) }
    }
  end

  def line_item_json(item)
    {
      id:               item.id,
      product_sku:      item.product_sku,
      name:             item.name,
      quantity:         item.quantity,
      unit_price_cents: item.unit_price_cents,
      subtotal_cents:   item.subtotal_cents
    }
  end
end
