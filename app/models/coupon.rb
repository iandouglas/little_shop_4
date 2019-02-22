class Coupon < ApplicationRecord
  belongs_to :user
  has_many :orders

  validates :name,
    presence: true,
    uniqueness: true,
    length: {
      minimum: 1
    }

  validates :value,
    presence: true,
    numericality: {
      greater_than_or_equal_to: 0
    }
end
