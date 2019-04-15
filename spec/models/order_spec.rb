require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'validations' do
    it {should validate_presence_of :status}
  end

  describe 'relationships' do
    it {should belong_to :user}
    it {should have_many :order_items}
    it {should have_many :items}
    it {should belong_to(:coupon).required(false)}
  end

  describe 'instance methods' do
    before :each do
      @user = create(:user)
      @merchant_1 = create(:merchant)
      @merchant_2 = create(:merchant)
      @item_1 = create(:item, user: @merchant_1)
      @item_2 = create(:item, user: @merchant_1)
      @item_3 = create(:item, user: @merchant_2)
      @order = create(:order, user: @user)
      @order_item_1 = create(:order_item, order: @order, item: @item_1, unit_price: 3, quantity: 1)
      @order_item_2 = create(:order_item, order: @order, item: @item_2, unit_price: 2, quantity: 5)
      @order_item_3 = create(:order_item, order: @order, item: @item_3, unit_price: 3, quantity: 10)
    end

    describe '.total_items_for_merchant(merchant)' do
      it 'returns the total quantity of a merchant\'s items in an order' do

        expect(@order.total_items_for_merchant(@merchant_1)).to eq(6)
      end
    end

    describe '.total_value_for_merchant(merchant)' do
      it 'returns the total value of a specific merchant\'s items in an order' do

        expect(@order.total_value_for_merchant(@merchant_1)).to eq(13)
      end
    end

    it '.quantity_of_items' do
      user = create(:user)
      item_1 = create(:item)
      item_2 = create(:item)
      order = create(:order, user: user)
      create(:order_item, order: order, item: item_1, quantity: 2)
      create(:order_item, order: order, item: item_2, quantity: 1)

      expect(order.quantity_of_items).to eq(3)
    end

    it '.grand_total' do
      user = create(:user)
      item_1 = create(:item)
      item_2 = create(:item)
      order = create(:order, user: user)
      create(:order_item, order: order, item: item_1, unit_price: 1.50, quantity: 2)
      create(:order_item, order: order, item: item_2, unit_price: 3.50, quantity: 1)

      expect(order.grand_total).to eq(6.5)
    end

    it '.ordered_items' do
      @item_1.update(price: "999.99")
      expect(@order.ordered_items.first.unit_price).to eq(@order_item_1.unit_price)
      expect(@order.ordered_items.first.quantity).to eq(@order_item_1.quantity)
      expect(@order.ordered_items.first.name).to eq(@item_1.name)
      expect(@order.ordered_items.first.merchant_id).to eq(@item_1.user_id)
    end

    it '.cancel' do
      user = create(:user)
      item_1 = create(:item)
      item_2 = create(:item)
      incomplete_order = create(:order, user: user, status: 0)
      create(:order_item, order: incomplete_order, item: item_1, unit_price: item_1.price)
      incomplete_order_item_2 = create(:order_item, order: incomplete_order, item: item_2, unit_price: item_2.price, fulfilled: true)

      incomplete_order.cancel

      cancelled_order = Order.find(incomplete_order.id)


      expect(cancelled_order.status).to eq('cancelled')
      expect(cancelled_order.order_items.first.fulfilled).to eq(false)
      expect(Item.find(item_2.id).quantity).to eq(item_2.quantity + incomplete_order_item_2.quantity)
    end
  end

  describe 'class methods' do
    before :each do
      @merchant_1 = create(:merchant)
      @merchant_2 = create(:merchant)
      @merchant_3 = create(:merchant)
      @merchant_4 = create(:merchant)

      @user_1 = create(:user, state: 'California', city: 'Los Angeles')
      @user_2 = create(:user, state: 'Florida', city: 'Wausau')
      @user_3 = create(:user, state: 'Wisconsin', city: 'Wausau')
      @user_4 = create(:user, state: 'Wisconsin', city: 'Green Bay')
      @user_5 = create(:user, state: 'Colorado', city: 'Denver')


      @item_1 = create(:item, user: @merchant_1, quantity: 100, price: 30)
      @item_2 = create(:item, user: @merchant_1, quantity: 100, price: 20)
      @item_3 = create(:item, user: @merchant_2, quantity: 100, price: 17)
      @item_4 = create(:item, user: @merchant_3, quantity: 100, price: 5)
      @item_5 = create(:item, user: @merchant_4, quantity: 100, price: 3)
      @item_6 = create(:item, user: @merchant_2, quantity: 100, price: 3)

      # User 1 from LA 4 orders:
      @order_1 = create(:order, user: @user_1, status: 'completed')
      create(:order_item, order: @order_1, item: @item_1, fulfilled: true)
      @order_2 = create(:order, user: @user_1, status: 'completed')
      create(:order_item, order: @order_2, item: @item_1, fulfilled: true)
      @order_3 = create(:order, user: @user_1, status: 'completed')
      create(:order_item, order: @order_3, item: @item_1, fulfilled: true)
      @order_4 = create(:order, user: @user_1, status: 'completed')
      create(:order_item, order: @order_4, item: @item_1, fulfilled: true)


      #User 2 from Florida's 3 orders:
      @order_5 = create(:order, user: @user_2, status: 'completed')
      create(:order_item, order: @order_5, item: @item_1, fulfilled: true)
      @order_6 = create(:order, user: @user_2, status: 'completed')
      create(:order_item, order: @order_6, item: @item_1, fulfilled: true)
      @order_7 = create(:order, user: @user_2, status: 'completed')
      create(:order_item, order: @order_7, item: @item_1, fulfilled: true)

      #User 3 from Wisconsin's 2 orders
      @order_8 = create(:order, user: @user_3, status: 'completed')
      create(:order_item, order: @order_8, item: @item_1, fulfilled: true)
      @order_9 = create(:order, user: @user_3, status: 'completed')
      create(:order_item, order: @order_9, item: @item_1, fulfilled: true)

      #User 4 from Wisconsin's 3 orders
      @order_10 = create(:order, user: @user_4, status: 'completed')
      create(:order_item, order: @order_10, item: @item_1, fulfilled: true)
      @order_11 = create(:order, user: @user_4, status: 'completed')
      create(:order_item, order: @order_11, item: @item_1, fulfilled: true)
      @order_12 = create(:order, user: @user_4, status: 'completed')
      create(:order_item, order: @order_12, item: @item_1, fulfilled: true)

      #User 5, from Colorado's two orders
      @order_13 = create(:order, user: @user_5, status: 'completed')
      create(:order_item, order: @order_13, item: @item_1, fulfilled: true)
      @order_14 = create(:order, user: @user_5, status: 'completed')
      create(:order_item, order: @order_14, item: @item_1, fulfilled: true)
    end

    describe '.pending_orders(merchant)' do
      it 'returns an array of all pending orders containing a specific merchant\'s items' do
        user = create(:user)
        merchant_1 = create(:merchant)
        merchant_2 = create(:merchant)
        item_1 = create(:item, user: merchant_1)
        item_2 = create(:item, user: merchant_2)
        order_1 = create(:order, user: user)
        order_2 = create(:order, user: user)
        order_3 = create(:order, user: user)
        order_4 = create(:cancelled_order, user: user)
        order_5 = create(:completed_order, user: user)
        create(:order_item, order: order_1, item: item_1, unit_price: 1, quantity: 1)
        create(:order_item, order: order_2, item: item_2, unit_price: 1, quantity: 1)
        create(:order_item, order: order_3, item: item_1, unit_price: 1, quantity: 1)
        create(:order_item, order: order_4, item: item_1, unit_price: 1, quantity: 1)
        create(:order_item, order: order_5, item: item_1, unit_price: 1, quantity: 1)

        expect(Order.pending_orders(merchant_1)).to eq([order_1, order_3])
      end
    end

    describe '.top_states' do
      it 'should return the top 3 states where any orders were shipped (by number of orders), and count of orders' do
        expect(Order.top_states[0].state).to eq("Wisconsin")
        expect(Order.top_states[1].state).to eq("California")
        expect(Order.top_states[2].state).to eq("Florida")
        expect(Order.top_states[0].order_count).to eq(5)
        expect(Order.top_states[1].order_count).to eq(4)
        expect(Order.top_states[2].order_count).to eq(3)
      end
    end

    describe '.top_cities' do
      it '3 cities where any orders were shipped (by number of orders), and the count of orders' do
        additional_order_for_la = create(:order, user: @user_1, status: 'completed')
        additional_order_for_green_bay = create(:order, user: @user_4, status: 'completed')
        create(:order_item, order: additional_order_for_la, item: @item_1, fulfilled: true)
        create(:order_item, order: additional_order_for_green_bay, item: @item_1, fulfilled: true)
        expect(Order.top_cities[0].location).to eq("Los Angeles, California")
        expect(Order.top_cities[0].city_quantity).to eq(5)

        expect(Order.top_cities[1].location).to eq("Green Bay, Wisconsin")
        expect(Order.top_cities[1].city_quantity).to eq(4)

        expect(Order.top_cities[2].location).to eq("Wausau, Florida")
        expect(Order.top_cities[2].city_quantity).to eq(3)
      end

    end

    describe '.biggest_orders' do
      it 'should return the top 3 biggest orders by quantity of items shipped in an order, plus their quantities' do
        OrderItem.destroy_all
        Order.destroy_all

        order_1 = create(:order, user: @user_1, status: 'completed')
        create(:order_item, order: order_1, item: @item_1, fulfilled: true, quantity: 10)
        order_2 = create(:order, user: @user_1, status: 'completed')
        create(:order_item, order: order_2, item: @item_1, fulfilled: true, quantity: 8)
        order_3 = create(:order, user: @user_1, status: 'completed')
        create(:order_item, order: order_3, item: @item_1, fulfilled: true, quantity: 5)
        order_4 = create(:order, user: @user_1, status: 'completed')
        create(:order_item, order: order_4, item: @item_1, fulfilled: true, quantity: 2)

        expect(Order.biggest_orders).to eq([order_1, order_2, order_3])
        expect(Order.biggest_orders[0].total_quantity).to eq(10)
        expect(Order.biggest_orders[1].total_quantity).to eq(8)
        expect(Order.biggest_orders[2].total_quantity).to eq(5)
      end
    end

  end
end
