require "test_helper"

class InventoriesTest < ActionDispatch::IntegrationTest
  setup do
    @admin  = users(:admin)
    @member = users(:member)
    @widget = products(:widget) # stock 10
  end

  test "viewing inventory requires authentication" do
    get product_inventory_path(@widget)
    assert_response :unauthorized
  end

  test "a member can view a product's inventory" do
    get product_inventory_path(@widget), headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal({ "product_id" => @widget.id, "quantity" => 10 }, response.parsed_body)
  end

  test "a product without an inventory row reports zero stock" do
    inventories(:widget_stock).destroy!
    get product_inventory_path(@widget), headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal 0, response.parsed_body["quantity"]
  end

  test "a member cannot set inventory" do
    patch product_inventory_path(@widget),
          params: { inventory: { quantity: 42 } },
          headers: bearer(access_token_for(@member)), as: :json
    assert_response :forbidden
  end

  test "an admin can set inventory" do
    patch product_inventory_path(@widget),
          params: { inventory: { quantity: 42 } },
          headers: bearer(access_token_for(@admin)), as: :json
    assert_response :ok
    assert_equal 42, inventories(:widget_stock).reload.quantity
  end

  test "negative inventory is rejected" do
    patch product_inventory_path(@widget),
          params: { inventory: { quantity: -1 } },
          headers: bearer(access_token_for(@admin)), as: :json
    assert_response :unprocessable_entity
  end
end
