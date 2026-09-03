require "test_helper"

class OrdersTest < ActionDispatch::IntegrationTest
  setup do
    @admin   = users(:admin)
    @member  = users(:member)
    @acme    = customers(:acme)
    @widget  = products(:widget)   # 1000 cents
    @gadget  = products(:gadget)   # 2500 cents
    @order   = orders(:acme_order)
  end

  test "listing orders requires authentication" do
    get orders_path
    assert_response :unauthorized
  end

  test "a member can place an order and the total is computed server-side" do
    assert_difference -> { Order.count }, 1 do
      post orders_path,
           params: { order: { customer_id: @acme.id,
                              order_items_attributes: [
                                { product_id: @widget.id, quantity: 2 },
                                { product_id: @gadget.id, quantity: 1 }
                              ] } },
           headers: bearer(access_token_for(@member)), as: :json
    end
    assert_response :created
    # 2 * 1000 + 1 * 2500 = 4500
    assert_equal 4500, response.parsed_body["total_cents"]
  end

  test "unit prices are snapshotted from the product at order time" do
    post orders_path,
         params: { order: { customer_id: @acme.id,
                            order_items_attributes: [{ product_id: @widget.id, quantity: 3 }] } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :created

    item = response.parsed_body["order_items"].first
    assert_equal @widget.price_cents, item["unit_price_cents"]
    assert_equal 3 * @widget.price_cents, item["subtotal_cents"]
  end

  test "a client-supplied total is ignored in favor of the computed one" do
    post orders_path,
         params: { order: { customer_id: @acme.id,
                            total_cents: 1,
                            order_items_attributes: [{ product_id: @widget.id, quantity: 2 }] } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :created
    assert_equal 2000, response.parsed_body["total_cents"]
  end

  test "a member cannot set the status when placing an order" do
    post orders_path,
         params: { order: { customer_id: @acme.id,
                            status: "paid",
                            order_items_attributes: [{ product_id: @widget.id, quantity: 1 }] } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :created
    assert_equal "pending", response.parsed_body["status"]
  end

  test "an order with no line items is rejected" do
    post orders_path,
         params: { order: { customer_id: @acme.id, order_items_attributes: [] } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :unprocessable_entity
  end

  test "a member cannot advance an order's status" do
    patch order_path(@order),
          params: { order: { status: "shipped" } },
          headers: bearer(access_token_for(@member)), as: :json
    assert_response :forbidden
  end

  test "an admin can advance an order's status" do
    patch order_path(@order),
          params: { order: { status: "shipped" } },
          headers: bearer(access_token_for(@admin)), as: :json
    assert_response :ok
    assert_equal "shipped", @order.reload.status
  end

  test "a member cannot delete an order" do
    delete order_path(@order), headers: bearer(access_token_for(@member))
    assert_response :forbidden
  end

  test "an admin can delete an order" do
    assert_difference -> { Order.count }, -1 do
      delete order_path(@order), headers: bearer(access_token_for(@admin))
    end
    assert_response :no_content
  end
end
