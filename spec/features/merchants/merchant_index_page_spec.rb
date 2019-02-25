require 'rails_helper'

include ApplicationHelper

RSpec.describe 'when I visit the merchant index page' do
  before :each do
    @active_merchants = create_list(:merchant, 4)

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


    @order_1 = create(:order, user: @user_1, status: 'completed')

    create(:order_item, order: @order_1, item: @item_1, unit_price: 30, quantity: 10, fulfilled: true, created_at: 60.seconds.ago, updated_at: 1.second.ago)
    create(:order_item, order: @order_1, item: @item_2, unit_price: 20, quantity: 10, fulfilled: true, created_at: 58.seconds.ago, updated_at: 1.second.ago)
    create(:order_item, order: @order_1, item: @item_6, unit_price: 3, quantity: 10, fulfilled: true, created_at: 31.seconds.ago, updated_at: 1.second.ago)
    #Order 1
    #Total: $530
    #From Merchant 1
    #Item 1  $30  10 = $300
    #Item 2 $20 10 = $200
    #Bought from Merchant 1 = $500
    #Took him about a minute to fulfill

    #From Merchant 2
    #Item 6 $3 10 - $30
    #Bought from Merchant 2 = $30
    #Took him 30 seconds to fulfill

    #Order 2
    #total: $340
    #From Merchant 2
    #Item 3 took him about
    #about 30 second to fulfill
    @order_2 = create(:order, user: @user_1, status: 'pending')

    create(:order_item, order: @order_2, item: @item_3, unit_price: 17, quantity: 20, fulfilled: true, created_at: 32.seconds.ago, updated_at: 1.second.ago)

    #Order 3
    #Total: $130
    #From Merchant 3 $100
    #Item 4 unit price: 5 quantity: 20
    #Took them 3 seconds to fulfill

    #From Merchant 4 $30
    #Item 5 unit price 3, quantity: 10
    #Took them 1 second to fulfill
    #

    @order_3 = create(:order, user: @user_1, status: 'completed')

    create(:order_item, order: @order_3, item: @item_4, unit_price: 5, quantity: 20, fulfilled: true, created_at: 4.seconds.ago, updated_at: 1.second.ago)
    create(:order_item, order: @order_3, item: @item_5, unit_price: 3, quantity: 10, fulfilled: true, created_at: 30.seconds.ago, updated_at: 29.seconds.ago)
  end

  context 'as a visitor' do
    it "I see a list of all merchants in the system" do
      visit merchants_path

      @active_merchants.each do |merchant|
        within "#merchant-#{merchant.id}" do
          expect(page).to have_content(merchant.name)
        end
      end
    end

    it 'I only see merchants who are active' do
      inactive_merchant = build(:inactive_merchant)
      inactive_merchant.save

      visit merchants_path

      expect(page).to_not have_css("#merchant-#{inactive_merchant.id}")
      expect(page).to_not have_content(inactive_merchant.name)
    end

    it "Next to each merchants name I also see their city and state" do
      visit merchants_path

      @active_merchants.each do |merchant|
        within "#merchant-#{merchant.id}" do
          expect(page).to have_content("From: #{merchant.city}, #{merchant.state}")
        end
      end
    end

    it "I also see the date each merchant registered" do
      visit merchants_path

      @active_merchants.each do |merchant|
        within "#merchant-#{merchant.id}" do
          expect(page).to have_content("Registered: #{merchant.created_at.strftime("%B, %d %Y")}")
        end
      end
    end
  end

  context 'in the statistics part of the page' do

    it 'I see a pie chart of all merchants who have completed orders and their revenue' do
      within '#statistics' do
        within '#merchants-by-revenue' do
          expect(page).to have_css('#merchants-by-revenue-chart')
          within "merchant-#{@merchant_1.id}" do
            expect(page).to have_content(number_to_currency(500))
          end

          within "merchant-#{@merchant_1.id}" do
            expect(page).to have_content(number_to_currency(100))
          end

          within "merchant-#{@merchant_1.id}" do
            expect(page).to have_content(number_to_currency(30))
          end

          within "merchant-#{@merchant_1.id}" do
            expect(page).to have_content(number_to_currency(30))
          end
        end
      end
    end

    it "I see the top 3 merchants by revenue and their revenue" do
      visit merchants_path

      within '#statistics' do
        within '#biggest-merchants' do
          biggest_merchants = page.find_all(".list-group-item")
          expect(page).to have_content("Top 3 Merchants by revenue")
          expect(biggest_merchants[0]).to have_content("#{@merchant_1.name}. Revenue: $500")
          expect(biggest_merchants[1]).to have_content("#{@merchant_2.name}. Revenue: $370")
          expect(biggest_merchants[2]).to have_content("#{@merchant_3.name}. Revenue: $100")
        end
      end
    end

    it "I see the top 3 fastest merchants and their times" do
      visit merchants_path

      within '#statistics' do
        within '#fastest-merchants' do
          fastest_merchants = page.find_all(".list-group-item")
          expect(page).to have_content("Top 3 Fastest Merchants")
          expect(fastest_merchants[0]).to have_content("#{@merchant_4.name}. Average Fulfillment Time: #{time_string("00:00:01")}")
          expect(fastest_merchants[1]).to have_content("#{@merchant_3.name}. Average Fulfillment Time: #{time_string("00:00:03")}")
          expect(fastest_merchants[2]).to have_content("#{@merchant_2.name}. Average Fulfillment Time: #{time_string("00:00:30")}")
        end
      end
    end

    it "I see the top 3 slowest merchants and their times" do
      visit merchants_path

      within '#statistics' do
        within '#slowest-merchants' do
          slowest_merchants = page.find_all(".list-group-item")
          expect(page).to have_content("Top 3 Slowest Merchants")
          expect(slowest_merchants[0]).to have_content("#{@merchant_1.name}. Average Fulfillment Time: #{time_string("00:00:58")}")
          expect(slowest_merchants[1]).to have_content("#{@merchant_2.name}. Average Fulfillment Time: #{time_string("00:00:30")}")
          expect(slowest_merchants[2]).to have_content("#{@merchant_3.name}. Average Fulfillment Time: #{time_string("00:00:03")}")
        end
      end
    end

    it 'I see the top 3 states where orders were shipped and their order count' do
      OrderItem.destroy_all
      Order.destroy_all
      Item.destroy_all
      User.destroy_all


      merchant_1 = create(:merchant)
      merchant_2 = create(:merchant)
      merchant_3 = create(:merchant)
      merchant_4 = create(:merchant)

      user_1 = create(:user, state: 'California', city: 'Los Angeles')
      user_2 = create(:user, state: 'Florida', city: 'Wausau')
      user_3 = create(:user, state: 'Wisconsin', city: 'Wausau')
      user_4 = create(:user, state: 'Wisconsin', city: 'Green Bay')
      user_5 = create(:user, state: 'Colorado', city: 'Denver')


      item_1 = create(:item, user: merchant_1, quantity: 100, price: 30)
      item_2 = create(:item, user: merchant_1, quantity: 100, price: 20)
      item_3 = create(:item, user: merchant_2, quantity: 100, price: 17)
      item_4 = create(:item, user: merchant_3, quantity: 100, price: 5)
      item_5 = create(:item, user: merchant_4, quantity: 100, price: 3)
      item_6 = create(:item, user: merchant_2, quantity: 100, price: 3)

      # User 1 from LA 4 orders:
      order_1 = create(:order, user: user_1, status: 'completed')
      create(:order_item, order: order_1, item: item_1, fulfilled: true)
      order_2 = create(:order, user: user_1, status: 'completed')
      create(:order_item, order: order_2, item: item_1, fulfilled: true)
      order_3 = create(:order, user: user_1, status: 'completed')
      create(:order_item, order: order_3, item: item_1, fulfilled: true)
      order_4 = create(:order, user: user_1, status: 'completed')
      create(:order_item, order: order_4, item: item_1, fulfilled: true)


      #User 2 from Florida's 3 orders:
      order_5 = create(:order, user: user_2, status: 'completed')
      create(:order_item, order: order_5, item: item_1, fulfilled: true)
      order_6 = create(:order, user: user_2, status: 'completed')
      create(:order_item, order: order_6, item: item_1, fulfilled: true)
      order_7 = create(:order, user: user_2, status: 'completed')
      create(:order_item, order: order_7, item: item_1, fulfilled: true)

      #User 3 from Wisconsin's 2 orders
      order_8 = create(:order, user: user_3, status: 'completed')
      create(:order_item, order: order_8, item: item_1, fulfilled: true)
      order_9 = create(:order, user: user_3, status: 'completed')
      create(:order_item, order: order_9, item: item_1, fulfilled: true)

      #User 4 from Wisconsin's 3 orders
      order_10 = create(:order, user: user_4, status: 'completed')
      create(:order_item, order: order_10, item: item_1, fulfilled: true)
      order_11 = create(:order, user: user_4, status: 'completed')
      create(:order_item, order: order_11, item: item_1, fulfilled: true)
      order_12 = create(:order, user: user_4, status: 'completed')
      create(:order_item, order: order_12, item: item_1, fulfilled: true)

      #User 5, from Colorado's two orders
      order_13 = create(:order, user: user_5, status: 'completed')
      create(:order_item, order: order_13, item: item_1, fulfilled: true)
      order_14 = create(:order, user: user_5, status: 'completed')
      create(:order_item, order: order_14, item: item_1, fulfilled: true)

      visit merchants_path

      within '#statistics' do
        within '#top-states' do
          top_states = page.find_all(".list-group-item")
          expect(top_states[0]).to have_content("Wisconsin. Number of orders: 5")
          expect(top_states[1]).to have_content("California. Number of orders: 4")
          expect(top_states[2]).to have_content("Florida. Number of orders: 3")
        end
      end
    end

    it 'I see the top 3 cities where orders were shipped and their order count' do
      additional_order_for_la = create(:order, user: @user_1, status: 'completed')
      additional_order_for_la_2 = create(:order, user: @user_1, status: 'completed')
      additional_order_for_la_3 = create(:order, user: @user_1, status: 'completed')
      order_for_green_bay = create(:order, user: @user_4, status: 'completed')
      order_for_green_bay_2 = create(:order, user: @user_4, status: 'completed')
      order_for_green_bay_3 = create(:order, user: @user_4, status: 'completed')
      order_for_green_bay_4 = create(:order, user: @user_4, status: 'completed')
      wausau_order = create(:order, user: @user_2, status: 'completed')
      wausau_order_2 = create(:order, user: @user_2, status: 'completed')
      wausau_order_3 = create(:order, user: @user_2, status: 'completed')
      create(:order_item, order: additional_order_for_la, item: @item_1, fulfilled: true)
      create(:order_item, order: additional_order_for_la_2, item: @item_1, fulfilled: true)
      create(:order_item, order: additional_order_for_la_3, item: @item_1, fulfilled: true)
      create(:order_item, order: order_for_green_bay, item: @item_1, fulfilled: true)


      visit merchants_path

      within '#statistics' do
        within '#top-cities' do
          top_cities = page.find_all(".list-group-item")
          expect(top_cities[0]).to have_content("Los Angeles, California. Number of orders: 5")
          expect(top_cities[1]).to have_content("Green Bay, Wisconsin. Number of orders: 4")
          expect(top_cities[2]).to have_content("Wausau, Florida. Number of orders: 3")
        end
      end
    end

    it 'I see the top 3 biggest orders and the order count' do

      OrderItem.destroy_all
      Order.destroy_all

      order_1 = create(:order, user: @user_1, status: 'completed')
      create(:order_item, order: order_1, item: @item_1, fulfilled: true, quantity: 100)
      order_2 = create(:order, user: @user_1, status: 'completed')
      create(:order_item, order: order_2, item: @item_1, fulfilled: true, quantity: 8)
      order_3 = create(:order, user: @user_1, status: 'completed')
      create(:order_item, order: order_3, item: @item_1, fulfilled: true, quantity: 5)
      order_4 = create(:order, user: @user_1, status: 'completed')
      create(:order_item, order: order_4, item: @item_1, fulfilled: true, quantity: 2)

      visit merchants_path


      within '#statistics' do
        within '#biggest-orders' do
          biggest_orders = page.find_all(".list-group-item")
          expect(biggest_orders[0]).to have_content("Order: #{order_1.id} Quantity: 10")
          expect(biggest_orders[1]).to have_content("Order: #{order_2.id} Quantity: 8")
          expect(biggest_orders[2]).to have_content("Order: #{order_3.id} Quantity: 5")
        end
      end
    end
   end

  context 'as an admin' do
    before :each do
      @admin = build(:admin)
      @admin.save
    end

    it 'next to each active merchants name I see a button to disable them' do
      login_as(@admin)
      visit merchants_path

      @active_merchants.each do |merchant|
        within "#merchant-#{merchant.id}" do
          expect(page).to have_button("Disable")
        end
      end
    end

    it 'next to each inactive_merchant I see a button to enable them' do
      inactive_merchant = build(:inactive_merchant)
      inactive_merchant.save
      login_as(@admin)
      visit merchants_path

      within "#merchant-#{inactive_merchant.id}" do
        expect(page).to have_button("Enable")
      end
    end

    it 'each merchant name is a link to their dashboard' do
      login_as(@admin)
      visit merchants_path

      @active_merchants.each do |merchant|
        within "#merchant-#{merchant.id}" do
          expect(page).to have_link(merchant.name)
        end
      end
    end

    it 'I can click the button to disable an enabled merchant' do
      login_as(@admin)

      visit merchants_path

      within "#merchant-#{@active_merchants.first.id}" do
        click_button 'Disable'
      end

      expect(page).to have_content "You have disabled a user"

      within "#merchant-#{@active_merchants.first.id}" do
        expect(page).to have_button('Enable')
      end

      click_link 'Logout'

      login_as(@active_merchants.first)

      expect(page).to have_content 'Invalid email and/or password'
    end

    it 'I can click a link to enable a disabled merchant' do
      inactive_merchant = build(:inactive_merchant)
      inactive_merchant.save
      login_as(@admin)

      visit merchants_path

      within "#merchant-#{inactive_merchant.id}" do
        click_button 'Enable'
      end

      expect(page).to have_content "You have enabled a user"

      within "#merchant-#{inactive_merchant.id}" do
        expect(page).to have_button('Disable')
      end

      click_link 'Logout'

      login_as(inactive_merchant)

      expect(page).to have_content("You are now logged in")
    end
  end
end
