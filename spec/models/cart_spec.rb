require 'rails_helper'

RSpec.describe Cart do
  before :each do
    @cart = Cart.new({
      "1" => "2",
      "2" => "3"
      })
  end
  describe '#total_count' do
    it 'can calculate the total number of items it holds' do
      expect(@cart.total_count).to eq(5)
    end
  end

  describe '#add_item' do
    it 'can add items' do
      @cart.add_item("1")
      @cart.add_item("2")

      expect(@cart.contents).to eq("1" => "3", "2" => "4")

    end
  end

  describe '#remove_item' do
    it 'can decrement an item' do
      @cart.remove_item("1")
      expect(@cart.contents).to eq("1" => "1", "2" => "3")
    end

    it 'deletes the key if value reaches zero an item' do
      @cart.remove_item("1")
      @cart.remove_item("1")
      expect(@cart.contents).to eq("2" => "3")
    end
  end

  describe '#clear_item' do
    it 'removes all of a given item' do
      @cart.clear_item("1")
      expect(@cart.contents).to eq("2" => "3")
    end
  end

  describe '#total' do
    it 'calculates the grand total for the contents of the cart' do
      merchant = build(:merchant)
      merchant.save
      cart = Cart.new(nil)

      item_1 = merchant.items.create!(name: "Thing 1", description: "It's a thing", image: "https://upload.wikimedia.org/wikipedia/en/5/53/Snoopy_Peanuts.png", price: 20, quantity: 1)
      item_2 = merchant.items.create!(name:"Thing 2", description: "It's a thing", image: "https://upload.wikimedia.org/wikipedia/en/5/53/Snoopy_Peanuts.png", price: 30, quantity: 5)

      cart.add_item(item_1.id.to_s)
      cart.add_item(item_1.id.to_s)
      cart.add_item(item_2.id.to_s)
      expect(cart.total).to eq(70)
    end

    it 'returns 0 if the cart is empty' do
      cart = Cart.new(nil)
      expect(cart.total).to eq(0)
    end
  end

  describe '.discounted_total' do
    before :each do
      @merchant = create(:merchant)
      @other_merchant = create(:merchant)
      @dollar_coupon = create(:coupon, value: 10, user: @merchant)
      @percentage_coupon = create(:percentage_coupon, value: 50, user: @merchant)
      @cart = Cart.new(nil)
      @item_1 = create(:item, price: 5.0, user: @merchant)
      @item_2 = create(:item, price: 10.0, user: @merchant)
      @item_3 = create(:item, price: 20.0, user: @other_merchant)
    end

    it 'returns a discounted total for a dollar based coupon' do
      @cart.add_item(@item_1.id.to_s)

      expect(@cart.discounted_total(@dollar_coupon)).to eq(0.0)

      @cart.add_item(@item_2.id.to_s)

      expect(@cart.discounted_total(@dollar_coupon)).to eq(@item_1.price + @item_2.price - @dollar_coupon.value)
    end

    it 'returns a discounted total for a percentage based coupon' do
      @cart.add_item(@item_1.id.to_s)

      expect(@cart.discounted_total(@percentage_coupon)).to eq(@item_1.price * @percentage_coupon.value / 100)

      @cart.add_item(@item_2.id.to_s)

      expect(@cart.discounted_total(@percentage_coupon)).to eq((@item_1.price + @item_2.price) * @percentage_coupon.value / 100)
    end

    it 'Only impacts items sold by the issuing merchant' do
      @cart.add_item(@item_1.id.to_s)
      @cart.add_item(@item_3.id.to_s)

      expect(@cart.discounted_total(@dollar_coupon)).to eq(20.0)

      @cart.contents.clear

      @cart.add_item(@item_1.id.to_s)
      @cart.add_item(@item_3.id.to_s)

      expect(@cart.discounted_total(@percentage_coupon)).to eq((@item_1.price * @percentage_coupon.value / 100) + @item_3.price)
    end
  end
end
