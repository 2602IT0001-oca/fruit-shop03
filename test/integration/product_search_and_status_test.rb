require "test_helper"

class ProductSearchAndStatusTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @apple = products(:one)
    @apple.update!(name: "青りんご", price: 300)
    @orange = products(:two)
    @orange.update!(name: "みかん", price: 200)
    @red = Product.create!(name: "赤りんご", price: 200)
  end

  test "name contains price equals and combined searches" do
    get products_url, params: { q: { name_cont: "りんご" } }
    assert_equal [ "赤りんご", "青りんご" ], product_names.sort
    get products_url, params: { q: { price_eq: 200 } }
    assert_equal [ "みかん", "赤りんご" ], product_names.sort
    get products_url, params: { q: { name_cont: "りんご", price_eq: 200 } }
    assert_equal [ "赤りんご" ], product_names
    get products_url, params: { q: { name_cont: "' OR 1=1 --" } }
    assert_empty product_names
    get products_url
    assert_equal 3, product_names.length
  end

  test "name and price sort in both directions while preserving conditions" do
    %w[name price].each do |attribute|
      %w[asc desc].each do |direction|
        get products_url, params: { q: { s: "#{attribute} #{direction}" } }
        assert_response :success
        values = css_select("tbody tr td:nth-child(#{attribute == 'name' ? 1 : 2})").map(&:text).map(&:strip)
        assert_equal 3, values.length
        sorted = attribute == "price" ? values.sort_by(&:to_i) : values.sort
        assert_equal direction == "asc" ? sorted : sorted.reverse, values
      end
    end
    get products_url, params: { q: { name_cont: "りんご", s: "price desc" } }
    assert_equal [ "青りんご", "赤りんご" ], product_names
    assert_select "a.sort_link[href*='name_cont']", minimum: 1
  end

  test "only name and price are available to ransack" do
    assert_equal %w[name price], Product.ransackable_attributes
    get products_url, params: { q: { description_cont: "not present", status_eq: "sold_out" } }
    assert_response :success
    assert_equal 3, product_names.length
  end

  test "admin edits sale status using japanese radio buttons" do
    admin = User.create!(name: "管理者", email: "status-admin@example.test", password: "password", admin_flg: true)
    sign_in admin
    get edit_product_url(@apple)
    assert_select "input[type=radio][name='product[status]']", count: 2
    assert_select "label", text: "販売中"
    assert_select "label", text: "売り切れ"
    patch product_url(@apple), params: { product: { status: "sold_out" } }
    assert_redirected_to product_path(@apple)
    assert @apple.reload.sold_out?
    patch product_url(@apple), params: { product: { status: "on_sale" } }
    assert @apple.reload.on_sale?
  end

  test "sold out products hide cart forms and reject guest and customer direct adds" do
    @apple.sold_out!
    get product_url(@apple)
    assert_select "p", text: "販売状況: 売り切れ"
    assert_select "input[type=submit][value='カートに追加']", count: 0
    post add_product_carts_url, params: { product_id: @apple.id, count: 1 }
    assert_redirected_to product_path(@apple)
    assert_empty session[:cart] || []
    user = User.create!(name: "購入者", email: "status-buyer@example.test", password: "password")
    sign_in user
    assert_no_difference "CartItem.count" do
      post cart_items_url, params: { cart_item: { product_id: @apple.id, quantity: 1 } }
    end
    assert_redirected_to product_path(@apple)
    patch product_url(@apple), params: { product: { status: "on_sale" } }
    assert_redirected_to products_path
    assert @apple.reload.sold_out?
  end

  test "sold out products in guest cart are not merged on login" do
    post add_product_carts_url, params: { product_id: @apple.id, count: 1 }
    @apple.sold_out!
    user = User.create!(name: "購入者", email: "merge-status@example.test", password: "password")
    post user_session_url, params: { user: { email: user.email, password: "password" } }
    follow_redirect!
    assert_empty user.reload.cart.cart_items
  end

  test "devise messages are japanese and application time zone is Tokyo" do
    post user_session_url, params: { user: { email: "missing@example.test", password: "wrong-password" } }
    assert_match /メールアドレスまたはパスワードが正しくありません/, response.body
    assert_equal :ja, I18n.default_locale
    assert_equal "Tokyo", Rails.application.config.time_zone
  end

  private

  def product_names
    css_select("tbody tr td:nth-child(1)").map(&:text).map(&:strip)
  end
end
