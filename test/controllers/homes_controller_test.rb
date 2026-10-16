require "test_helper"

class HomesControllerTest < ActionDispatch::IntegrationTest
  test "top page lists products without signing in" do
    get root_url
    assert_response :success
    assert_select "h2", "商品一覧"
    assert_select "a[href=?]", product_path(products(:one)), text: products(:one).name
  end
end
