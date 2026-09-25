class Order < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :count, numericality: { only_integer: true, greater_than: 0 }
  validates :address, presence: true
end
