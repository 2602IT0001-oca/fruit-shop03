module PriceCalculations
  private

  def calculate_item_total(price, count)
    price * count
  end

  def calculate_total_sum(items)
    items.sum
  end

  def cart_calculation
    session[:cart] ||= []
    products = Product.where(id: session[:cart].map { |item| item["id"] }).index_by(&:id)
    # 閲覧後に管理者が削除した商品は、セッションカートから取り除く。
    session[:cart].select! { |item| products.key?(item["id"]) }
    session[:cart].each do |item|
      item["price"] = products.fetch(item["id"]).price
      item["item_price"] = calculate_item_total(item["price"], item["count"])
    end
    session[:cart_total] = calculate_total_sum(session[:cart].map { |item| item["item_price"] })
  end

  def user_cart_calculation
    cart = current_user.cart
    @item_totals = cart.cart_items.includes(:product).map do |item|
      calculate_item_total(item.product.price, item.quantity)
    end
    @cart_total = calculate_total_sum(@item_totals)
  end
end
