require 'rails_helper'

RSpec.describe Coupon, type: :model do
  describe 'relationships' do
    it {should belong_to :user}
    it {should have_many :orders}
  end

  describe 'validations' do
    it {should validate_presence_of :name}
    it {should validate_uniqueness_of :name}
    it {should validate_length_of(:name)
        .is_at_least(1)
    }

    it {should validate_presence_of :value}
    it {should validate_numericality_of(:value)
        .is_greater_than_or_equal_to(0)
    }
  end

  describe 'instance methods' do
    describe '.unused?' do
      it 'returns a boolean indicating if the coupon has ever been used' do
        unused_coupon = create(:coupon)
        order = create(:order)
        used_coupon = create(:coupon)
        order.update(coupon: used_coupon)

        expect(unused_coupon.unused?).to eq(true)
        expect(used_coupon.unused?).to eq(false)
      end
    end
  end

  describe 'class methods' do
  end
end
