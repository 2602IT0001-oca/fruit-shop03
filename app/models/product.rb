class Product < ApplicationRecord
  has_many :order_details, dependent: :restrict_with_error
  has_many :orders, through: :order_details
  has_many :cart_items, dependent: :destroy
  has_many :carts, through: :cart_items
  has_one_attached :photo

  validates :name, presence: true, uniqueness: true
  validates :price, presence: true

  enum :status, { on_sale: 0, sold_out: 1 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[name price]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def thumbnail
    photo.variant(resize_to_limit: [ 150, 150 ]).processed
  end
end
