require 'rails_helper'

RSpec.describe 'admin views merchant dashboard' do
  describe 'as an admin when Im on the merchant index page and I click on a merchant name' do
    before :each do
      @merchant = create(:merchant)
      @item_1 = create(:item, user: @merchant, quantity: 10)
      @item_2 = create(:item, user: @merchant, quantity: 10)
      @item_3 = create(:item, user: @merchant, quantity: 10)
      @item_4 = create(:item, user: @merchant, quantity: 10)
      @item_5 = create(:item, user: @merchant, quantity: 10)
      @item_6 = create(:item, user: @merchant, quantity: 10)
      @user_1 = create(:user, state: 'California', city: 'Los Angeles')
      @user_2 = create(:user, state: 'Florida', city: 'Wausau')
      @user_3 = create(:user, state: 'Wisconsin', city: 'Wausau')
      @user_4 = create(:user, state: 'Wisconsin', city: 'Green Bay')
      @order_1 = create(:order, user: @user_1, status: 'completed')
      @order_2 = create(:order, user: @user_2, status: 'pending')
      @order_3 = create(:order, user: @user_3, status: 'completed')
      @order_4 = create(:order, user: @user_3, status: 'completed')
      @order_5 = create(:order, user: @user_4, status: 'completed')
      create(:order_item, order: @order_1, item: @item_1, unit_price: 100, quantity: 1, fulfilled: true)
      create(:order_item, order: @order_2, item: @item_2, unit_price: 2, quantity: 2, fulfilled: true)
      create(:order_item, order: @order_2, item: @item_3, unit_price: 2, quantity: 3, fulfilled: true)
      create(:order_item, order: @order_3, item: @item_4, unit_price: 2, quantity: 3, fulfilled: true)
      create(:order_item, order: @order_4, item: @item_6, unit_price: 2, quantity: 4, fulfilled: true)
      create(:order_item, order: @order_5, item: @item_6, unit_price: 2, quantity: 1, fulfilled: true)
      create(:order_item, order: @order_2, item: @item_4, unit_price: 2, quantity: 1, fulfilled: true)
      create(:order_item, order: @order_4, item: @item_2, unit_price: 2, quantity: 1, fulfilled: true)
      create(:order_item, order: @order_5, item: @item_3, unit_price: 2, quantity: 1, fulfilled: true)
      admin = create(:admin)

      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    it 'takes me to the route admin/merchants/:id' do
      visit merchants_path

      click_on "#{@merchant.name}"

      expect(current_path).to eq(admin_merchant_path(@merchant))
    end

    it 'redirects me to the user profile if that user is not a merchant' do
      visit admin_merchant_path(@user_1)

      expect(current_path).to eq(admin_user_path(@user_1))
      expect(page).to have_content("#{@user_1.name}'s profile")
    end


    describe 'I see what the merchant sees' do
      it 'I see their profile data' do
        visit admin_merchant_path(@merchant)

        expect(page).to have_content("Name: #{@merchant.name}")
        expect(page).to have_content("Email: #{@merchant.email}")
        expect(page).to have_content("Address: #{@merchant.address}")
        expect(page).to have_content("City: #{@merchant.city}")
        expect(page).to have_content("State: #{@merchant.state}")
        expect(page).to have_content("Zipcode: #{@merchant.zipcode}")
      end

      it 'I see a list of pending orders containing items they sell' do
        visit admin_merchant_path(@merchant)

        within(class: "order-#{@order_2.id}") do
          expect(page).to have_content("##{@order_2.id}")
          expect(page).to have_content("#{@order_2.created_at.localtime.strftime("%m-%d-%Y")}")
          expect(page).to have_content("#{@order_2.total_items_for_merchant(@merchant)}")
          expect(page).to have_content("$#{@order_2.total_value_for_merchant(@merchant)}")
        end

        expect(page).to_not have_content("Order ID: #{@order_1.id}")

        click_link "#{@order_2.id}"
        expect(current_path).to eq(admin_order_path(@order_2))
      end

      it 'I see an area with statistics about their ordered items' do
        visit admin_merchant_path(@merchant)
        within(class: "statistics") do
          expect(page).to have_content("#{@merchant.top_items_for_merchant(5).first.name}")
          expect(page).to have_content("#{@merchant.top_items_for_merchant(5).first.total_quantity}")
          expect(page).to have_content("You have sold #{@merchant.items_sold_by_quantity} items which is #{number_to_percentage(@merchant.items_sold_by_percentage * 100, strip_insignificant_zeros: true)} of your total inventory.")
          expect(page).to have_content("#{@merchant.top_states(3).first.state}")
          expect(page).to have_content("#{@merchant.top_states(3).first.state_quantity}")
          expect(page).to have_content("#{@merchant.top_cities(3).first.location}")
          expect(page).to have_content("#{@merchant.top_cities(3).first.city_quantity}")
          expect(page).to have_content("#{@merchant.top_customer_by_orders.name}")
          expect(page).to have_content("#{@merchant.top_customer_by_orders.order_count}")
          expect(page).to have_content("#{@merchant.top_customer_by_items.name}")
          expect(page).to have_content("#{@merchant.top_customer_by_items.item_count}")
          expect(page).to have_content("#{@merchant.top_spenders(3).first.name}")
          expect(page).to have_content("$#{@merchant.top_spenders(3).first.total_spent}")
        end
      end

      it 'I see a pie chart representing the merchants inventory sold' do
        visit admin_merchant_path(@merchant)

        within(".statistics") do
          expect(page).to have_css('svg')
          expect(page).to have_css('#inventory-chart')
        end
      end

      it 'I see a bar graph representing the merchants revenue by month for the past 12 months' do
        new_merchant = create(:merchant)
        new_item = create(:item, user: new_merchant)
        january = create(:order_item, quantity: 2, item: new_item, created_at: 1.month.ago)
        january = create(:order_item, quantity: 6, item: new_item, created_at: 1.month.ago)
        december = create(:order_item, quantity: 3, item: new_item, created_at: 2.months.ago)
        november = create(:order_item, quantity: 4, item: new_item, created_at: 3.months.ago)
        october = create(:order_item, quantity: 4, item: new_item, created_at: 4.months.ago)
        september = create(:order_item, quantity: 2, item: new_item, created_at: 5.months.ago)
        august = create(:order_item, quantity: 1, item: new_item, created_at: 6.months.ago)
        july = create(:order_item, quantity: 8, item: new_item, created_at: 7.months.ago)

        visit admin_merchant_path(new_merchant)

        within(".statistics") do
          expect(page).to have_css('#revenue-by-month-chart')
        end
      end

      it 'I see a link that directs me to items' do
        visit admin_merchant_path(@merchant)

        click_link 'My Items'

        expect(current_path).to eq(admin_merchant_items_path(@merchant))
        expect(page).to have_content("#{@item_1.name}")
      end
    end
  end
end
