class User < ApplicationRecord
  validates :name,
            presence: true,
            length: { minimum: 2 },
            uniqueness: true

  validates :age,
            presence: true,
            numericality: { only_integer: true }

  validates :password,
            presence: true,
            length: { in: 6..20 },
            confirmation: true

  validates :password_confirmation,
            presence: true

  validates :email,
            format: {
              with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i,
              message: "使用できない文字が含まれているか形式に誤りがあります。"
            },
            uniqueness: true

   devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable
end