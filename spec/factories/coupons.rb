FactoryBot.define do
  factory :coupon do
    user { "" }
    name { "MyString" }
    percent { false }
    value { 1.5 }
  end
end
