class OrdersController < ApplicationController
  before_action :authenticate_user!

  def new
    @order = Order.new
    @product = Product.find(params[:product_id])
  end

  def index
    @orders = current_user.orders.all
  end

  def confirm
    @order = Order.new(order_params)
    @product = Product.find(order_params[:product_id])
    @order.user = current_user

    if @order.valid?
      @order.total_price = cal_total_price(@product.price, @order.count)
    else
      render :new and return
    end
  end

  def create
    @order = Order.new(order_params)
    @order.user_id = current_user.id

    if @order.save
      redirect_to complete_order_path(@order)
    else
      @product = Product.find(@order.product_id)
      redirect_to new_order_path(product_id: @order.product_id)
    end
  end

  def complete
    @order = Order.find(params[:id])
    @product = Product.find(@order.product_id)
  end

  private

  def order_params
    params.require(:order).permit(:total_price, :address, :count, :product_id)
  end

  def cal_total_price(price, count)
    return price * count
  end
end
