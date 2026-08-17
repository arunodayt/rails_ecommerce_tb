require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  setup do
    @order = orders(:acme_order) # total 2000 cents, 2 x widget @ 1000
  end

  test "generate_for! computes tax from the manually supplied percentage rate" do
    invoice = Invoice.generate_for!(@order, tax_rate: 18)

    assert_equal 2000, invoice.subtotal_cents
    assert_equal 360, invoice.tax_cents
    assert_equal 2360, invoice.total_cents
    assert_equal "issued", invoice.status
  end

  test "generate_for! assigns a unique invoice number" do
    invoice = Invoice.generate_for!(@order, tax_rate: 10)
    assert_equal format("INV-%04d-%06d", invoice.issued_at.year, invoice.id), invoice.number
  end

  test "generate_for! snapshots line items, billing and merchant details" do
    invoice = Invoice.generate_for!(@order, tax_rate: 10)

    assert_equal 1, invoice.invoice_line_items.count
    line = invoice.invoice_line_items.first
    assert_equal "WIDGET-001", line.product_sku
    assert_equal 2, line.quantity
    assert_equal 1000, line.unit_price_cents

    assert_equal "Acme Corp", invoice.billing_name
    assert_equal "1 Acme Way", invoice.billing_address["line1"]
    assert_equal "Rampvera Inc.", invoice.merchant_name

    # later product edits must not affect the issued invoice
    products(:widget).update!(name: "Renamed", price_cents: 9999)
    assert_equal "Widget", line.reload.name
    assert_equal 1000, line.unit_price_cents
  end

  test "tax_rate is required and bounded" do
    assert_raises(ActiveRecord::RecordInvalid) { Invoice.generate_for!(@order, tax_rate: nil) }
    assert_raises(ActiveRecord::RecordInvalid) { Invoice.generate_for!(@order, tax_rate: 101) }
  end

  test "an order can only have one issued invoice at a time" do
    Invoice.generate_for!(@order, tax_rate: 10)
    assert_raises(ActiveRecord::RecordInvalid) { Invoice.generate_for!(@order, tax_rate: 10) }
  end

  test "voiding an invoice allows reissuing" do
    first = Invoice.generate_for!(@order, tax_rate: 10)
    first.update!(status: "void")

    second = Invoice.generate_for!(@order, tax_rate: 12)
    assert second.persisted?
  end

  test "a void invoice cannot change status again" do
    invoice = Invoice.generate_for!(@order, tax_rate: 10)
    invoice.update!(status: "void")
    assert_not invoice.update(status: "issued")
  end
end
