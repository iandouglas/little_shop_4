FactoryBot.define do
  factory :coupon do
    association :user, factory: :merchant
    sequence(:name) { |n| "Coupon ##{n}" }
    sequence(:value) { |n| n * 1.5 }
    percent { false }
    disabled { false }
  end

  factory :percentage_coupon, parent: :coupon do
    sequence(:name) { |n| "Percentage Coupon ##{n}" }
    percent { true }
  end

  factory :inactive_coupon, parent: :coupon do
    sequence(:name) { |n| "Inactive Coupon ##{n}" }
    disabled { true }
  end
end
