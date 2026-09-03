require "test_helper"

class InvoicesTest < ActionDispatch::IntegrationTest
  setup do
    @admin  = users(:admin)
    @member = users(:member)
    @order  = orders(:acme_order) # total 2000 cents
  end

  test "issuing an invoice requires authentication" do
    post order_invoices_path(@order), params: { invoice: { tax_rate: 18 } }, as: :json
    assert_response :unauthorized
  end

  test "a member cannot issue an invoice" do
    post order_invoices_path(@order),
         params: { invoice: { tax_rate: 18 } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :forbidden
  end

  test "an admin can issue an invoice with tax computed from the supplied rate" do
    post order_invoices_path(@order),
         params: { invoice: { tax_rate: 18 } },
         headers: bearer(access_token_for(@admin)), as: :json
    assert_response :created

    body = response.parsed_body
    assert_equal 2000, body["subtotal_cents"]
    assert_equal 360, body["tax_cents"]
    assert_equal 2360, body["total_cents"]
    assert_equal "issued", body["status"]
    assert_match(/\AINV-\d{4}-\d{6}\z/, body["number"])
    assert_equal "Acme Corp", body["billing_name"]
    assert_equal "1 Acme Way", body["billing_address"]["line1"]
    assert_equal "Acme Inc.", body["merchant_name"]
    assert_equal [%w[WIDGET-001 2]].map { |sku, qty| [sku, qty.to_i] },
                 body["line_items"].map { |item| [item["product_sku"], item["quantity"]] }
  end

  test "a missing tax rate is rejected" do
    post order_invoices_path(@order),
         params: { invoice: { tax_rate: nil } },
         headers: bearer(access_token_for(@admin)), as: :json
    assert_response :unprocessable_entity
  end

  test "an order cannot be invoiced twice while an invoice is issued" do
    Invoice.generate_for!(@order, tax_rate: 10)

    post order_invoices_path(@order),
         params: { invoice: { tax_rate: 10 } },
         headers: bearer(access_token_for(@admin)), as: :json
    assert_response :unprocessable_entity
  end

  test "an admin can void an invoice and reissue" do
    invoice = Invoice.generate_for!(@order, tax_rate: 10)

    patch invoice_path(invoice),
          params: { invoice: { status: "void" } },
          headers: bearer(access_token_for(@admin)), as: :json
    assert_response :ok
    assert_equal "void", invoice.reload.status

    post order_invoices_path(@order),
         params: { invoice: { tax_rate: 12 } },
         headers: bearer(access_token_for(@admin)), as: :json
    assert_response :created
  end

  test "a member cannot void an invoice" do
    invoice = Invoice.generate_for!(@order, tax_rate: 10)

    patch invoice_path(invoice),
          params: { invoice: { status: "void" } },
          headers: bearer(access_token_for(@member)), as: :json
    assert_response :forbidden
  end

  test "invoices can be listed and shown" do
    invoice = Invoice.generate_for!(@order, tax_rate: 10)

    get invoices_path, headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal [invoice.id], response.parsed_body.map { |i| i["id"] }

    get invoice_path(invoice), headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal invoice.number, response.parsed_body["number"]
  end
end
