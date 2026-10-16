class ApplicationController < ActionController::Base
  include PriceCalculations

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_recent_product
  before_action :prepare_cart, if: :user_signed_in?

  def after_sign_in_path_for(resource)
    mypage_path(resource)
  end

  def after_sign_out_path_for(_resource_or_scope)
    session.delete(:cart_merged)
    root_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name admin_flg])
  end

  private

  def store_recent_product
    return unless controller_name == "products" && action_name == "show"
    return unless Product.exists?(params[:id])

    product_id = params[:id].to_i
    session[:recent_product_ids] ||= []
    session[:recent_product_ids].delete(product_id)
    session[:recent_product_ids].unshift(product_id)
    session[:recent_product_ids] = session[:recent_product_ids].take(5)
  end

  def prepare_cart
    return if current_user.admin_flg?

    cart = Cart.find_or_create_by!(user_id: current_user.id)
    return if session[:cart_merged] || session[:cart].blank?

    Cart.transaction do
      session[:cart].each do |item|
        product = Product.find_by(id: item["id"])
        next unless product && item["count"].to_i.positive?

        cart_item = cart.cart_items.find_or_initialize_by(product: product)
        cart_item.quantity += item["count"].to_i
        cart_item.save!
      end
    end
    session.delete(:cart)
    session.delete(:cart_total)
    session[:cart_merged] = true
  end
end
