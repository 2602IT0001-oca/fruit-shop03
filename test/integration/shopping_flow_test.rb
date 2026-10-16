require "test_helper"

class ShoppingFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(name: "購入者", email: "buyer@example.test", password: "password")
    @other = User.create!(name: "別の購入者", email: "other@example.test", password: "password")
    @product = products(:one)
  end

  test "session cart adds quantities refreshes prices and removes zero quantities" do
    post add_product_carts_url, params: { product_id: @product.id, count: 2 }
    assert_redirected_to carts_path
    post add_product_carts_url, params: { product_id: @product.id, count: 3 }
    assert_equal 5, session[:cart].first["count"]
    @product.update!(price: 250)
    get carts_url
    assert_response :success
    assert_equal 1250, session[:cart_total]
    post update_quantity_cart_url(@product), params: { count: 0 }
    assert_empty session[:cart]
    assert_equal 0, session[:cart_total]
    delete remove_item_cart_url(@product)
    assert_redirected_to carts_path
  end

  test "quantities above 99 remain selected in guest and database carts" do
    post add_product_carts_url, params: { product_id: @product.id, count: 150 }
    get carts_url
    assert_select "select[name=count] option[selected][value='150']"
    sign_in @user
    get mypage_url(@user)
    get cart_url(@user.reload.cart)
    assert_select "select[name='cart_item[quantity]'] option[selected][value='150']"
  end

  test "invalid guest quantities do not change the cart" do
    [0, -1, "1.5", "bad"].each do |count|
      post add_product_carts_url, params: { product_id: @product.id, count: count }
      assert_redirected_to product_path(@product)
      assert_empty session[:cart] || []
    end
  end

  test "real sign in merges the guest cart once and preserves existing database quantities" do
    cart = @user.create_cart!
    item = cart.cart_items.create!(product: @product, quantity: 4)
    post add_product_carts_url, params: { product_id: @product.id, count: 2 }
    post user_session_url, params: { user: { email: @user.email, password: "password" } }
    assert_redirected_to mypage_path(@user)
    follow_redirect!
    assert_response :success
    assert_equal 6, item.reload.quantity
    assert_nil session[:cart]
    get cart_url(cart)
    assert_response :success
    assert_equal 6, item.reload.quantity
    assert_select "a[href=?]", new_order_path(product_id: @product.id, count: 6), text: "この商品を注文する"
    delete destroy_user_session_url
    follow_redirect!
    post add_product_carts_url, params: { product_id: @product.id, count: 1 }
    post user_session_url, params: { user: { email: @user.email, password: "password" } }
    follow_redirect!
    assert_equal 7, item.reload.quantity
  end

  test "signup keeps the guest cart and displays registration errors" do
    post add_product_carts_url, params: { product_id: @product.id, count: 2 }
    post user_registration_url, params: { user: { name: "", email: "", password: "x", password_confirmation: "x" } }
    assert_response :unprocessable_content
    assert_select "#error_explanation li"
    post user_registration_url, params: { user: {
      name: "新規購入者", email: "new@example.test",
      password: "password", password_confirmation: "password", admin_flg: "0"
    } }
    new_user = User.find_by!(email: "new@example.test")
    assert_redirected_to mypage_path(new_user)
    follow_redirect!
    assert_response :success
    assert_equal 2, new_user.cart.cart_items.find_by!(product: @product).quantity
  end

  test "signed in cart quantity updates removals and ownership checks" do
    other_item = @other.create_cart!.cart_items.create!(product: @product, quantity: 1)
    sign_in @user
    get mypage_url(@user)
    assert_response :success
    get cart_url(@user.reload.cart)
    assert_response :success
    assert_select "p", text: "カートは空です。"
    post cart_items_url, params: { cart_item: { product_id: @product.id, quantity: 2 } }
    item = @user.cart.cart_items.find_by!(product: @product)
    post cart_items_url, params: { cart_item: { product_id: @product.id, quantity: 1 } }
    assert_equal 3, item.reload.quantity
    patch cart_item_url(other_item), params: { cart_item: { quantity: 8 } }
    assert_response :not_found
    assert_equal 1, other_item.reload.quantity
    delete cart_item_url(other_item)
    assert_response :not_found
    patch cart_item_url(item), params: { cart_item: { quantity: -1 } }
    assert_equal 3, item.reload.quantity
    patch cart_item_url(item), params: { cart_item: { quantity: 0 } }
    assert_not CartItem.exists?(item.id)
    post cart_items_url, params: { cart_item: { product_id: @product.id, quantity: 1 } }
    item = @user.cart.cart_items.find_by!(product: @product)
    delete cart_item_url(item)
    assert_not CartItem.exists?(item.id)
  end

  test "guest requests to database cart endpoints require sign in" do
    get cart_url(1)
    assert_redirected_to new_user_session_path
    post cart_items_url, params: { cart_item: { product_id: @product.id, quantity: 1 } }
    assert_redirected_to new_user_session_path
  end

  test "admin neither merges a guest cart nor changes a customer cart" do
    admin = User.create!(name: "管理者", email: "admin@example.test", password: "password", admin_flg: true)
    post add_product_carts_url, params: { product_id: @product.id, count: 2 }
    sign_in admin
    get products_url
    assert_response :success
    assert_nil admin.reload.cart
    assert_equal 2, session[:cart].first["count"]
    post cart_items_url, params: { cart_item: { product_id: @product.id, quantity: 1 } }
    assert_redirected_to products_path
    assert_nil admin.reload.cart
  end

  test "recent products are unique limited to five and tolerate deletion" do
    products = 6.times.map { |i| Product.create!(name: "閲覧商品#{i}", price: 100) }
    products.each { |product| get product_url(product); assert_response :success }
    assert_equal products.last(5).reverse.map(&:id), session[:recent_product_ids]
    get product_url(products.last)
    assert_equal 5, session[:recent_product_ids].size
    products.last.destroy!
    get root_url
    assert_response :success
  end

  test "single product orders validate and recalculate the stored price" do
    sign_in @user
    @product.update!(price: 300)
    get new_order_url(product_id: @product.id, count: 2)
    assert_response :success
    post confirm_orders_url, params: { order: { product_id: @product.id, count: 0, address: "" } }
    assert_response :unprocessable_entity
    post confirm_orders_url, params: { order: { product_id: @product.id, count: 2, address: "大阪市" } }
    assert_response :success
    assert_select "input[name='order[total_price]'][value='600']"
    assert_difference "Order.count", 1 do
      post orders_url, params: { order: { product_id: @product.id, count: 2, address: "大阪市", total_price: 1 } }
    end
    order = @user.orders.last
    assert_equal 600, order.total_price
    follow_redirect!
    assert_response :success
    get orders_url
    assert_response :success
    sign_out @user
    sign_in @other
    get complete_order_url(order)
    assert_response :not_found
  end

  test "deleting an ordered product returns a useful error without breaking order history" do
    Order.create!(user: @user, product: @product, count: 1, address: "大阪", total_price: @product.price)
    admin = User.create!(name: "管理者", email: "admin@example.test", password: "password", admin_flg: true)
    sign_in admin
    assert_no_difference "Product.count" do
      delete product_url(@product)
    end
    assert_redirected_to product_path(@product)
    assert flash[:alert].present?
  end
end
