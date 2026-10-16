Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  resources :mypage, only: :show
  resources :products

  resources :orders, only: %i[index new create] do
    collection do
      post :confirm
    end
    member do
      get :complete
    end
  end

  resources :carts, only: %i[show index] do
    collection do
      post :add_product
    end
    member do
      delete :remove_item
      post :update_quantity
    end
  end
  resources :cart_items, only: %i[create update destroy]

  root "homes#top"
  get "up" => "rails/health#show", as: :rails_health_check
end
