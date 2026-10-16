class CartsController < ApplicationController
  before_action :authenticate_user!, only: :show
  before_action :check_customer, only: :show
  before_action :redirect_signed_in_user, except: :show

  def show
    @cart = current_user.cart
    user_cart_calculation
  end

  def index
    cart_calculation
    @products = Product.where(id: session[:cart].map { |item| item["id"] }).index_by(&:id)
  end

  def add_product
    product = Product.find(cart_params[:product_id])
    count = Integer(cart_params[:count].to_s, 10, exception: false)
    unless count&.positive?
      redirect_to product_path(product), alert: "個数は1以上の整数を入力してください。"
      return
    end

    session[:cart] ||= []
    item = session[:cart].find { |entry| entry["id"] == product.id }
    if item
      item["count"] += count
    else
      session[:cart] << { "id" => product.id, "count" => count }
    end
    cart_calculation
    redirect_to carts_path, notice: "商品がカートに追加されました。", status: :see_other
  end

  def update_quantity
    count = Integer(params[:count].to_s, 10, exception: false)
    unless count && count >= 0
      redirect_to carts_path, alert: "個数は0以上の整数を入力してください。"
      return
    end

    session[:cart] ||= []
    item = session[:cart].find { |entry| entry["id"] == params[:id].to_i }
    if item
      item["count"] = count
      session[:cart].delete(item) if count.zero?
    end
    cart_calculation
    redirect_to carts_path, notice: "商品数量が更新されました。", status: :see_other
  end

  def remove_item
    session[:cart] ||= []
    session[:cart].delete_if { |item| item["id"] == params[:id].to_i }
    cart_calculation
    redirect_to carts_path, notice: "商品がカートから削除されました。", status: :see_other
  end

  private

  def cart_params
    params.permit(:product_id, :count)
  end

  def redirect_signed_in_user
    return unless user_signed_in?

    if current_user.admin_flg?
      redirect_to products_path
    else
      redirect_to cart_path(current_user.cart)
    end
  end

  def check_customer
    redirect_to products_path, alert: "一般ユーザーでログインしてください。" if current_user.admin_flg?
  end
end
