# app/config/routes.rb

Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  resources :mypage, only: [:show]
  resources :products

  resources :orders, only: [:index, :new, :create] do
    collection do
      post :confirm
    end
    member do
      get :complete
    end
  end

  delete "products/:id", to: "products#destroy", as: :destroy_product

  root "homes#top"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
