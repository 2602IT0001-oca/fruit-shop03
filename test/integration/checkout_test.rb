require "test_helper"

class CheckoutTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(name: "購入者", email: "checkout@example.test", password: "password")
    sign_in @user
    get mypage_url(@user)
    @cart = @user.reload.cart
    @product = products(:one)
    @product.update!(price: 250)
    @item = @cart.cart_items.create!(product: @product, quantity: 2)
  end

  test "empty carts do not enter checkout or create orders" do
    @item.destroy!
    get new_order_url
    assert_redirected_to cart_path(@cart)
    assert_no_difference "Order.count" do
      post orders_url, params: { order: { address: "東京", total_price: 0 } }
    end
    assert_redirected_to cart_path(@cart)
  end

  test "confirmation builds unsaved details and displays textbook hidden fields" do
    assert_no_difference [ "Order.count", "OrderDetail.count" ] do
      post confirm_orders_url, params: { order: { address: "東京" } }
    end
    assert_response :success
    assert_select "input[name='order[total_price]'][value='500']"
    assert_select "input[name='order[order_details_attributes[0][quantity]]'][value='2']"
    assert_equal 2, @item.reload.quantity
  end

  test "blank address returns to the input page without changing the cart" do
    assert_no_difference [ "Order.count", "OrderDetail.count" ] do
      post confirm_orders_url, params: { order: { address: "" } }
      assert_redirected_to new_order_path
      post orders_url, params: { order: { address: "", total_price: 500 } }
      assert_redirected_to new_order_path
    end
    assert_equal 2, @item.reload.quantity
  end

  test "sold out cart products cannot be checked out even by direct requests" do
    @product.sold_out!
    assert_no_difference [ "Order.count", "OrderDetail.count" ] do
      post confirm_orders_url, params: { order: { address: "東京" } }
      assert_redirected_to cart_path(@cart)
      post orders_url, params: { order: { address: "東京", total_price: 500 } }
      assert_redirected_to cart_path(@cart)
    end
    assert_equal 2, @item.reload.quantity
  end

  test "cart URLs cannot expose a different users cart" do
    other = User.create!(name: "他人", email: "other-cart@example.test", password: "password")
    get cart_url(other.create_cart!)
    assert_response :not_found
  end

  test "admin and guest cannot submit customer orders" do
    sign_out @user
    get new_order_url
    assert_redirected_to new_user_session_path
    admin = User.create!(name: "管理者", email: "checkout-admin@example.test", password: "password", admin_flg: true)
    sign_in admin
    [ new_order_url, confirm_orders_url, orders_url ].each_with_index do |url, index|
      index.zero? ? get(url) : post(url, params: { order: { address: "東京", total_price: 500 } })
      assert_redirected_to products_path
    end
    assert_empty @user.orders
  end
end
