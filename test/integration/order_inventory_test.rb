require "test_helper"

class OrderInventoryTest < ActionDispatch::IntegrationTest
  setup do
    @admin  = users(:admin)
    @member = users(:member)
    @acme   = customers(:acme)
    @widget = products(:widget)  # stock 10
    @gadget = products(:gadget)  # stock 5
    @order  = orders(:acme_order) # 2 x widget, pending
  end

  test "placing an order deducts inventory" do
    post orders_path,
         params: { order: { customer_id: @acme.id,
                            order_items_attributes: [
                              { product_id: @widget.id, quantity: 3 },
                              { product_id: @gadget.id, quantity: 2 }
                            ] } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :created
    assert_equal 7, inventories(:widget_stock).reload.quantity
    assert_equal 3, inventories(:gadget_stock).reload.quantity
  end

  test "an order exceeding stock fails and nothing is deducted" do
    assert_no_difference -> { Order.count } do
      post orders_path,
           params: { order: { customer_id: @acme.id,
                              order_items_attributes: [
                                { product_id: @widget.id, quantity: 2 },
                                { product_id: @gadget.id, quantity: 6 }
                              ] } },
           headers: bearer(access_token_for(@member)), as: :json
    end
    assert_response :unprocessable_entity
    assert_match(/Insufficient inventory for GADGET-001/, response.parsed_body["errors"].join)
    assert_equal 10, inventories(:widget_stock).reload.quantity
    assert_equal 5, inventories(:gadget_stock).reload.quantity
  end

  test "a product with no inventory row cannot be ordered" do
    inventories(:gadget_stock).destroy!
    post orders_path,
         params: { order: { customer_id: @acme.id,
                            order_items_attributes: [{ product_id: @gadget.id, quantity: 1 }] } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :unprocessable_entity
  end

  test "cancelling an order restocks its items" do
    patch order_path(@order),
          params: { order: { status: "cancelled" } },
          headers: bearer(access_token_for(@admin)), as: :json
    assert_response :ok
    assert_equal 12, inventories(:widget_stock).reload.quantity
  end

  test "reopening a cancelled order deducts inventory again" do
    @order.update!(status: "cancelled") # restocks to 12

    patch order_path(@order),
          params: { order: { status: "pending" } },
          headers: bearer(access_token_for(@admin)), as: :json
    assert_response :ok
    assert_equal 10, inventories(:widget_stock).reload.quantity
  end

  test "reopening a cancelled order fails when stock has run out" do
    @order.update!(status: "cancelled")
    inventories(:widget_stock).update!(quantity: 1)

    patch order_path(@order),
          params: { order: { status: "pending" } },
          headers: bearer(access_token_for(@admin)), as: :json
    assert_response :unprocessable_entity
    assert_equal "cancelled", @order.reload.status
    assert_equal 1, inventories(:widget_stock).reload.quantity
  end

  test "deleting a pending order restocks its items" do
    delete order_path(@order), headers: bearer(access_token_for(@admin))
    assert_response :no_content
    assert_equal 12, inventories(:widget_stock).reload.quantity
  end

  test "deleting a cancelled order does not restock twice" do
    @order.update!(status: "cancelled") # restocks to 12

    delete order_path(@order), headers: bearer(access_token_for(@admin))
    assert_response :no_content
    assert_equal 12, inventories(:widget_stock).reload.quantity
  end
end
