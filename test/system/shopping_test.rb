require "application_system_test_case"

class ShoppingTest < ApplicationSystemTestCase
  setup do
    @apple = products(:one)
    @apple.update!(name: "りんご", price: 300)
    @orange = products(:two)
    @orange.update!(name: "みかん", price: 200)
  end

  test "guest cart is merged on login and multiple products can be ordered from the forms" do
    buyer = User.create!(name: "画面確認購入者", email: "system-buyer@example.test", password: "password")
    visit product_path(@apple)
    fill_in "count", with: "2"
    click_button "カートに追加"
    assert_text "カートの中身"
    assert_text "¥600"

    click_link "ログイン"
    sign_in_from_form(buyer)
    assert_text "マイページ"
    click_link "カート"
    assert_text "ユーザーカートの中身"
    assert_selector "tbody tr", count: 1

    visit product_path(@orange)
    fill_in "cart_item_quantity", with: "3"
    click_button "カートに追加"
    assert_selector "tbody tr", count: 2
    click_link "注文へ進む"
    fill_in "order_address", with: "大阪市システムテスト"
    click_button "注文確認"
    assert_selector "h1", exact_text: "注文確認"
    assert_selector "tbody tr", count: 2
    assert_selector "input[name='order[total_price]'][value='1200']", visible: :all
    click_button "注文確定"
    assert_text "ご注文が完了しました。"
    assert_selector "tbody tr", count: 2
    assert_equal 1200, buyer.orders.sole.total_price
    assert_equal 2, buyer.orders.sole.order_details.count

    click_link "注文履歴"
    assert_text "大阪市システムテスト"
    assert_selector "tbody tr", count: 2
    click_link "カート"
    assert_text "カートは空です。"
  end

  test "admin can search for a product and change its sale status from the edit form" do
    admin = User.create!(name: "画面確認管理者", email: "system-admin@example.test", password: "password", admin_flg: true)
    visit new_user_session_path
    sign_in_from_form(admin)
    click_link "商品一覧"
    fill_in "q_name_cont", with: "りんご"
    fill_in "q_price_eq", with: "300"
    find("form#product_search input[type=submit]").click
    assert_selector "tbody tr", count: 1
    assert_text "りんご"
    click_link "詳細"
    click_link "編集"
    choose "product_status_sold_out"
    click_button "更新"
    assert_text "販売状況: 売り切れ"
    assert @apple.reload.sold_out?

    Capybara.reset_sessions!
    visit product_path(@apple)
    assert_text "販売状況: 売り切れ"
    assert_no_button "カートに追加"
  end

  private

  def sign_in_from_form(user)
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "ログイン"
  end
end
