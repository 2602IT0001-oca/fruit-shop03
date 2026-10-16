class CartItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_customer

  def create
    product = Product.find(cart_item_params[:product_id])
    quantity = Integer(cart_item_params[:quantity].to_s, 10, exception: false)
    unless quantity&.positive?
      redirect_to product_path(product), alert: "個数は1以上の整数を入力してください。"
      return
    end

    cart_item = current_user.cart.cart_items.find_or_initialize_by(product: product)
    cart_item.quantity += quantity
    if cart_item.save
      user_cart_calculation
      redirect_to cart_path(current_user.cart), notice: "商品がカートに追加されました。", status: :see_other
    else
      redirect_to product_path(product), alert: "商品をカートに追加できませんでした。"
    end
  end

  def update
    cart_item = current_user.cart.cart_items.find(params[:id])
    quantity = Integer(cart_item_params[:quantity].to_s, 10, exception: false)
    success = if quantity == 0
      cart_item.destroy
    else
      cart_item.update(quantity: cart_item_params[:quantity])
    end
    user_cart_calculation
    message = success ? "商品数量が更新されました。" : "商品数量の更新に失敗しました。"
    redirect_to cart_path(current_user.cart), success ? { notice: message, status: :see_other } : { alert: message, status: :see_other }
  end

  def destroy
    cart_item = current_user.cart.cart_items.find(params[:id])
    cart_item.destroy!
    user_cart_calculation
    redirect_to cart_path(current_user.cart), notice: "商品がカートから削除されました。", status: :see_other
  end

  private

  def cart_item_params
    params.require(:cart_item).permit(:product_id, :quantity)
  end

  def check_customer
    redirect_to products_path, alert: "一般ユーザーでログインしてください。" if current_user.admin_flg?
  end
end
