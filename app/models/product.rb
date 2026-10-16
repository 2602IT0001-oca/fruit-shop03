class Product < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error
  has_many :cart_items, dependent: :destroy
  has_one_attached :photo

  validates :name, presence: true, uniqueness: true
  validates :price, presence: true

  def thumbnail
    photo.variant(resize_to_limit: [150, 150]).processed
  end
end
