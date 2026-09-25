# app/config/routes.rb

Rails.application.routes.draw do
  devise_for :users
  resources :users
  # 商品登録
  get 'products/new'
  post 'products', to: 'products#create'  # 登録

  # 商品一覧
  get 'products', to: 'products#index'

  # 商品詳細
  get 'products/:id', to: 'products#show', as: 'product'

  # 商品編集
  get 'products/:id/edit', to: 'products#edit', as: 'edit_product'
  patch 'products/:id', to: 'products#update'

  # 商品削除
  delete 'products/:id', to: 'products#destroy', as: 'destroy_product'

  # トップページ
  root to: "homes#top"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end