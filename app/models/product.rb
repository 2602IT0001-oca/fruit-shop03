class Product < ApplicationRecord
      # バリデーション
  validates :name, presence: true, uniqueness: true  # 商品名は必須で一意
  validates :price, presence: true                   # 価格は必須
end
