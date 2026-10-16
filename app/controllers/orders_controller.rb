class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_customer, only: %i[new confirm create]

  def new
    unless params[:product_id].present?
      redirect_to products_path, alert: "注文する商品を選択してください。"
      return
    end
    @order = Order.new
    @product = Product.find(params[:product_id])
    @order.count = params[:count] if params[:count].present?
  end

  def index
    @orders = current_user.orders.includes(:product).all
  end

  def confirm
    @order = current_user.orders.new(order_params)
    @product = Product.find(@order.product_id)
    if @order.valid?
      @order.total_price = cal_total_price(@product.price, @order.count)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create
    @order = current_user.orders.new(order_params)
    @product = Product.find(@order.product_id)
    # 合計金額はhiddenフィールドを信用せず、保存時にも計算する。
    if @order.valid?
      @order.total_price = cal_total_price(@product.price, @order.count)
      @order.save!
      redirect_to complete_order_path(@order), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def complete
    @order = current_user.orders.find(params[:id])
    @product = @order.product
  end

  private

  def order_params
    params.require(:order).permit(:address, :count, :product_id)
  end

  def cal_total_price(price, count)
    price * count
  end

  def check_customer
    redirect_to products_path, alert: "一般ユーザーでログインしてください。" if current_user.admin_flg?
  end
end
