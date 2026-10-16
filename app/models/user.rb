class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :trackable, :rememberable, :validatable

  validates :name, presence: true

  has_many :orders
  has_one :cart, dependent: :destroy
end
