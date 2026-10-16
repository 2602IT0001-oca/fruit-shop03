require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(name: "管理者", email: "admin@example.test", password: "password", admin_flg: true)
  end

  test "guests can browse but cannot change products" do
    get products_url
    assert_response :success
    get product_url(products(:one))
    assert_response :success
    get new_product_url
    assert_redirected_to new_user_session_path
    assert_no_difference "Product.count" do
      post products_url, params: { product: { name: "禁止商品", price: 100 } }
    end
  end

  test "admin can create edit and delete a product" do
    sign_in @admin
    get new_product_url
    assert_response :success
    assert_difference "Product.count", 1 do
      post products_url, params: { product: { name: "みかん", price: 200, description: "新商品" } }
    end
    product = Product.find_by!(name: "みかん")
    get edit_product_url(product)
    assert_response :success
    patch product_url(product), params: { product: { price: 300 } }
    assert_redirected_to product_path(product)
    assert_equal 300, product.reload.price
    assert_difference "Product.count", -1 do
      delete product_url(product)
    end
    assert_redirected_to products_path
  end

  test "invalid product keeps the edit form and shows validation errors" do
    sign_in @admin
    patch product_url(products(:one)), params: { product: { name: "" } }
    assert_response :unprocessable_entity
    assert_select "#error_explanation li"
  end


  test "invalid new products keep the form and do not create records" do
    sign_in @admin
    [
      { name: "", price: 100 },
      { name: products(:one).name, price: 100 },
      { name: "価格なし", price: "" }
    ].each do |attributes|
      assert_no_difference "Product.count" do
        post products_url, params: { product: attributes }
      end
      assert_response :unprocessable_entity
      assert_select "#error_explanation li", minimum: 1
    end
  end

  test "product photo is uploaded and resized within 150 pixels" do
    sign_in @admin
    post products_url, params: { product: {
      name: "写真つき商品", price: 300,
      photo: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png", true)
    } }
    product = Product.find_by!(name: "写真つき商品")
    assert product.photo.attached?
    image = MiniMagick::Image.read(product.thumbnail.download)
    assert_operator image.width, :<=, 150
    assert_operator image.height, :<=, 150
    get product_url(product)
    assert_response :success
    assert_select "img[alt=?]", product.name
  end
end
