require "test_helper"

class ProductsTest < ActionDispatch::IntegrationTest
  setup do
    @admin   = users(:admin)
    @manager = users(:manager)
    @member  = users(:member)
    @widget  = products(:widget)
  end

  # --- auth gating -------------------------------------------------------

  test "listing products requires authentication" do
    get products_path
    assert_response :unauthorized
  end

  # --- read access -------------------------------------------------------

  test "a member can list products" do
    get products_path, headers: bearer(access_token_for(@member))
    assert_response :ok
  end

  test "members only see active products in the listing" do
    get products_path, headers: bearer(access_token_for(@member))
    names = response.parsed_body.map { |p| p["name"] }
    assert_includes names, products(:widget).name
    assert_not_includes names, products(:discontinued).name
  end

  test "admins see inactive products too" do
    get products_path, headers: bearer(access_token_for(@admin))
    names = response.parsed_body.map { |p| p["name"] }
    assert_includes names, products(:discontinued).name
  end

  test "a member can view a single product" do
    get product_path(@widget), headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal @widget.price_cents, response.parsed_body["price_cents"]
  end

  # --- write access ------------------------------------------------------

  test "a member cannot create a product" do
    post products_path,
         params: { product: { sku: "SPROCKET-1", name: "Sprocket", price_cents: 300 } },
         headers: bearer(access_token_for(@member)), as: :json
    assert_response :forbidden
  end

  test "an admin can create a product" do
    assert_difference -> { Product.count }, 1 do
      post products_path,
           params: { product: { sku: "SPROCKET-1", name: "Sprocket", description: "round", price_cents: 300 } },
           headers: bearer(access_token_for(@admin)), as: :json
    end
    assert_response :created
    assert_equal 300, response.parsed_body["price_cents"]
    assert_equal "SPROCKET-1", response.parsed_body["sku"]
  end

  test "a manager can update a product" do
    patch product_path(@widget),
          params: { product: { price_cents: 1500 } },
          headers: bearer(access_token_for(@manager)), as: :json
    assert_response :ok
    assert_equal 1500, @widget.reload.price_cents
  end

  test "a member cannot delete a product" do
    delete product_path(@widget), headers: bearer(access_token_for(@member))
    assert_response :forbidden
  end

  test "creating a product with a negative price is rejected" do
    post products_path,
         params: { product: { sku: "BAD-1", name: "Bad", price_cents: -1 } },
         headers: bearer(access_token_for(@admin)), as: :json
    assert_response :unprocessable_entity
  end

  # --- sku (unique product code) -----------------------------------------

  test "a product is returned with its sku" do
    get product_path(@widget), headers: bearer(access_token_for(@member))
    assert_response :ok
    assert_equal @widget.sku, response.parsed_body["sku"]
  end

  test "creating a product without a sku is rejected" do
    post products_path,
         params: { product: { name: "No Code", price_cents: 100 } },
         headers: bearer(access_token_for(@admin)), as: :json
    assert_response :unprocessable_entity
  end

  test "creating a product with a duplicate sku is rejected" do
    post products_path,
         params: { product: { sku: @widget.sku, name: "Clone", price_cents: 100 } },
         headers: bearer(access_token_for(@admin)), as: :json
    assert_response :unprocessable_entity
  end

  test "sku uniqueness is case-insensitive" do
    post products_path,
         params: { product: { sku: @widget.sku.downcase, name: "Clone", price_cents: 100 } },
         headers: bearer(access_token_for(@admin)), as: :json
    assert_response :unprocessable_entity
  end

  test "sku is normalized to uppercase on create" do
    post products_path,
         params: { product: { sku: "  lower-99  ", name: "Cased", price_cents: 100 } },
         headers: bearer(access_token_for(@admin)), as: :json
    assert_response :created
    assert_equal "LOWER-99", response.parsed_body["sku"]
  end
end
