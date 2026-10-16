class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_customer, only: %i[new confirm create]
  before_action :check_cart, only: %i[new confirm create]

  def new
    @order = Order.new
    @cart_items = current_user.cart.cart_items.includes(:product)
    user_cart_calculation
  end

  def confirm
    @order = Order.new(order_params)
    @order.user_id = current_user.id
    @cart_item = current_user.cart.cart_items.includes(:product)
    @cart_item.each do |item|
      @order.order_details.build(
        product_id: item.product.id,
        quantity: item.quantity,
        price: item.product.price
      )
    end
    item_totals = @order.order_details.map do |detail|
      calculate_item_total(detail.price, detail.quantity)
    end
    @order.total_price = calculate_total_sum(item_totals)
    if !@order.valid?
      redirect_to new_order_path, alert: "注文内容に誤りがあります。"
    end
  end

  def create
    @order = Order.new(order_params)
    @order.user_id = current_user.id
    if @order.save
      current_user.cart.cart_items.each do |item|
        OrderDetail.create(
          order_id: @order.id,
          product_id: item.product.id,
          quantity: item.quantity,
          price: item.product.price
        )
      end
      current_user.cart.cart_items.destroy_all
      redirect_to complete_order_path(@order), status: :see_other
    else
      redirect_to new_order_path, alert: "注文内容に誤りがあります。"
    end
  end

  def complete
    @order = current_user.orders.find(params[:id])
  end

  def index
    @orders = current_user.orders.order(created_at: :desc)
  end

  private

  def order_params
    # 07-11で削除したproduct_id・countを07-09のパラメータから取り除く。
    params.require(:order).permit(:address, :total_price)
  end

  def check_cart
    cart = current_user.cart
    if cart.cart_items.empty?
      redirect_to cart_path(cart), alert: "カートは空です。"
    elsif cart.cart_items.joins(:product).merge(Product.sold_out).exists?
      redirect_to cart_path(cart), alert: "売り切れの商品をカートから削除してください。"
    end
  end

  def check_customer
    redirect_to products_path, alert: "一般ユーザーでログインしてください。" if current_user.admin_flg?
  end
end
