require 'rails_helper'

RSpec.describe 'cart show page', type: :feature do
  include ActionView::Helpers
  before :each do
    @merchant = create(:merchant)
    @item_1 = @merchant.items.create(name: "Thing 1", description: "It's a thing", image: "https://upload.wikimedia.org/wikipedia/en/5/53/Snoopy_Peanuts.png", price: 5.0, quantity: 2)
    @item_2 = @merchant.items.create(name: "Thing 2", description: "It's another thing", image: "https://upload.wikimedia.org/wikipedia/en/5/53/Snoopy_Peanuts.png", price: 7.0, quantity: 2)
  end
  it 'as a user or visitor with no items in my cart, I see a message that my cart is empty' do
    visit cart_path

    expect(page).to have_content("Your cart is empty.")
  end

  it 'it allows me to add items to the cart, shows me a flash message and changes the cart counter in my nav bar' do
    visit item_path(@item_1)

    click_on "Add to Shopping Cart"

    expect(current_path).to eq(items_path)
    expect(page).to have_content("You now have 1 copy of #{@item_1.name} in your cart!")
    expect(page).to have_content("Cart: 1")
  end

  it 'shows all items that I have added to my cart in the cart/s show page' do
    visit item_path(@item_1)
    click_on "Add to Shopping Cart"

    visit item_path(@item_1)
    click_on "Add to Shopping Cart"

    expect(page).to have_content("Cart: 2")

    click_on "Cart"

    expect(current_path).to eq(cart_path)
    expect(page).to have_content(@item_1.name)

    expect(page).to have_css("img[src*='#{@item_1.image}']")
    expect(page).to have_content(@merchant.name)
    expect(page).to have_content(@item_1.price)
    expect(page).to have_content("Quantity: 2")
    expect(page).to have_content("Subtotal: $10.00")
    expect(page).to have_content("Total: $10")
  end

  describe 'coupons' do
    before :each do
      @unused_coupon = create(:coupon, user: @merchant, value: 3.0)
      @percentage_coupon = create(:percentage_coupon, user: @merchant, value: 50.0)
      @inactive_coupon = create(:inactive_coupon, user: @merchant)
      @user = create(:user)
      add_item_to_cart(@item_1)
    end

    it "An empty cart does not display a field to add a coupon" do
      visit logout_path # Clear cart
      visit cart_path

      expect(page).to_not have_button("Add Coupon")
    end

    it 'I see a field to enter a coupon code when I view my cart' do
      visit cart_path

      fill_in 'coupon', with: @unused_coupon.name
      click_button 'Add Coupon'

      expect(current_path).to eq(cart_path)
      expect(page).to have_content "Coupon \"#{@unused_coupon.name}\" has been applied."
      expect(page).to have_content "Current Coupon: #{@unused_coupon.name}"
    end

    it 'when I add a coupon, I see a "discounted total"' do
      visit cart_path

      fill_in 'coupon', with: @unused_coupon.name
      click_button 'Add Coupon'

      expect(page).to have_content "Discounted Total: #{number_to_currency(@item_1.price - @unused_coupon.value)}"

      fill_in 'coupon', with: @percentage_coupon.name
      click_button 'Add Coupon'

      expect(page).to have_content "Discounted Total: #{number_to_currency(@item_1.price * (100 - @percentage_coupon.value) / 100)}"
    end

    it 'Coupons entered persist when viewing other pages' do
      visit cart_path

      fill_in 'coupon', with: @unused_coupon.name
      click_button 'Add Coupon'

      visit items_path
      visit cart_path

      expect(page).to have_content "Current Coupon: #{@unused_coupon.name}"
      expect(page).to have_content "Discounted Total: #{number_to_currency(@item_1.price - @unused_coupon.value)}"
    end

    it 'If I enter an invalid coupon code I see a message indicating the code is invalid' do
      visit cart_path

      fill_in 'coupon', with: "#{@unused_coupon.name + "ABCDE"}"
      click_button 'Add Coupon'

      expect(current_path).to eq(cart_path)
      expect(page).to have_content "Invalid coupon name."
      expect(page).to_not have_content "Current Coupon: #{@unused_coupon.name}"
      expect(page).to_not have_content "Discounted Total:"
    end

    it 'If I enter an deactivated coupon code I see a message indicating the code is invalid' do
      visit cart_path

      fill_in 'coupon', with: "#{@inactive_coupon.name}"
      click_button 'Add Coupon'

      expect(current_path).to eq(cart_path)
      expect(page).to have_content "Invalid coupon name."
      expect(page).to_not have_content "Current Coupon: #{@inactive_coupon.name}"
      expect(page).to_not have_content "Discounted Total:"
    end

    it 'If I try and use a coupon I have used before, I see a message' do
      order = @user.orders.create(coupon: @unused_coupon)
      login_as(@user)

      visit cart_path

      fill_in 'coupon', with: @unused_coupon.name
      click_button 'Add Coupon'

      expect(page).to have_content "Coupon \"#{@unused_coupon.name}\" has already been redeemed."
      expect(page).to_not have_content 'Current Coupon:'
      expect(page).to_not have_content 'Discounted Total:'
    end

    it 'If I add a coupon I have used before, it is removed when logging in' do
      create(:order, coupon: @unused_coupon, user: @user)

      visit cart_path
      fill_in 'coupon', with: @unused_coupon.name
      click_button 'Add Coupon'
      expect(page).to have_content "Current Coupon: #{@unused_coupon.name}"

      login_as(@user)
      expect(page).to have_content "Coupon \"#{@unused_coupon.name}\" has been removed. (Already redeemed)"

      visit cart_path

      expect(page).to_not have_content 'Current Coupon:'
      expect(page).to_not have_content 'Discounted Total:'
    end

    it 'Coupons only apply discounts to items sold by the issuing merchant' do
      other_merchants_item = create(:item)
      add_item_to_cart(other_merchants_item)

      visit cart_path
      fill_in 'coupon', with: @unused_coupon.name
      click_button 'Add Coupon'

      expected_value = number_to_currency(@item_1.price - @unused_coupon.value + other_merchants_item.price)

      expect(page).to have_content "Discounted Total: #{expected_value}"
    end

    it 'Coupons discounts cannot reduce total cost below 0' do
      free_item = create(:item, price: 0, user: @merchant)
      visit logout_path # reset cart
      add_item_to_cart(free_item)

      visit cart_path
      fill_in 'coupon', with: @unused_coupon.name
      click_button 'Add Coupon'

      expect(page).to have_content "Discounted Total: #{number_to_currency(0)}"
    end

    it 'Percentage coupons discounts cannot reduce total cost below 0' do
      excessive_percentage_coupon = create(:percentage_coupon, value: 101, user: @merchant)
      free_item = create(:item, price: 0, user: @merchant)
      visit logout_path # reset cart
      add_item_to_cart(free_item)

      visit cart_path
      fill_in 'coupon', with: excessive_percentage_coupon.name
      click_button 'Add Coupon'

      expect(page).to have_content "Discounted Total: #{number_to_currency(0)}"
    end

    it 'users can remove coupons from their cart' do
      visit cart_path
      fill_in 'coupon', with: @unused_coupon.name
      click_button 'Add Coupon'
      expect(page).to have_content "Current Coupon: #{@unused_coupon.name}"

      click_button 'Remove Coupon'

      expect(page).to have_content "Coupon \"#{@unused_coupon.name}\" has been removed."

      expect(page).to_not have_content 'Current Coupon:'
      expect(page).to_not have_content 'Discounted Total:'
    end
  end

  describe 'checking out with coupons' do
    before :each do
      @user = create(:user)
      @merchant_1 = create(:merchant)
      @merchant_2 = create(:merchant)
      @item_1 = create(:item, user: @merchant_1, price: 10.0)
      @item_2 = create(:item, user: @merchant_2, price: 50.0)
      @percentage_coupon = create(:percentage_coupon, user: @merchant_1, value: 25.0)
      @high_value_percentage_coupon = create(:percentage_coupon, user: @merchant_1, value: 125.0)
      @dollar_coupon= create(:coupon, user: @merchant_2, value: 10.0)
      @high_value_dollar_coupon = create(:coupon, user: @merchant_2, value: 100.0)
      login_as(@user)
      add_item_to_cart(@item_1)
      add_item_to_cart(@item_2)
    end

    it 'I can checkout with a percentage based coupon' do
      visit cart_path
      fill_in 'coupon', with: @percentage_coupon.name
      click_button 'Add Coupon'

      click_button 'Checkout'

      visit profile_order_path(Order.last)

      within "#item-#{@item_1.id}" do
        expect(page).to have_content("Price: #{number_to_currency(@item_1.price * (1 - (@percentage_coupon.value / 100)))}")
      end

      within "#item-#{@item_2.id}" do
        expect(page).to have_content("Price: #{number_to_currency(@item_2.price)}")
      end

      expect(page).to have_content("Grand total: #{number_to_currency(@item_1.price * (1 - (@percentage_coupon.value / 100)) + @item_2.price)}")
    end

    it 'I can checkout with a percentage based coupon and not recieve a negative total' do
      visit cart_path
      fill_in 'coupon', with: @high_value_percentage_coupon.name
      click_button 'Add Coupon'

      click_button 'Checkout'

      visit profile_order_path(Order.last)

      within "#item-#{@item_1.id}" do
        expect(page).to have_content("Price: #{number_to_currency(0)}")
      end

      within "#item-#{@item_2.id}" do
        expect(page).to have_content("Price: #{number_to_currency(@item_2.price)}")
      end

      expect(page).to have_content("Grand total: #{number_to_currency(@item_2.price)}")
    end

    it 'I can checkout with a dollar based coupon' do
      visit cart_path
      fill_in 'coupon', with: @dollar_coupon.name
      click_button 'Add Coupon'

      click_button 'Checkout'

      visit profile_order_path(Order.last)

      within "#item-#{@item_1.id}" do
        expect(page).to have_content("Price: #{number_to_currency(@item_1.price)}")
      end

      within "#item-#{@item_2.id}" do
        expect(page).to have_content("Price: #{number_to_currency(@item_2.price - @dollar_coupon.value)}")
      end

      expect(page).to have_content("Grand total: #{number_to_currency(@item_2.price - @dollar_coupon.value + @item_1.price)}")
    end

    it 'I can checkout with a dollar based coupon with a value higher than my item price' do
      visit cart_path
      fill_in 'coupon', with: @high_value_dollar_coupon.name
      click_button 'Add Coupon'

      click_button 'Checkout'

      visit profile_order_path(Order.last)

      within "#item-#{@item_1.id}" do
        expect(page).to have_content("Price: #{number_to_currency(@item_1.price)}")
      end

      within "#item-#{@item_2.id}" do
        expect(page).to have_content("Price: #{number_to_currency(0)}")
      end

      expect(page).to have_content("Grand total: #{number_to_currency(@item_1.price)}")
    end

    it 'If I checkout with a coupon in my cart it is not present in my next order' do
      fill_in 'coupon', with: @percentage_coupon.name
      click_button 'Add Coupon'

      click_button 'Checkout'

      add_item_to_cart(@item_2)

      visit cart_path

      expect(page).to_not have_content('Current Coupon:')
      expect(page).to_not have_content('Discounted Total:')
    end
  end


  context "as a visitor" do
    it 'I don\'t see a button to checkout' do
      visit root_path
      click_on "Cart"

      expect(page).to_not have_button('Checkout')
    end

    describe "when I have items in my cart" do
      describe "and I visit the cart show page" do
        it "I see a message telling me to register or login in order to checkout" do
          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          click_on "Cart"

          expect(current_path).to eq(cart_path)

          expect(page).to have_content("You must login or register to checkout.")
          expect(page).to have_link("login", exact: true)
          expect(page).to have_link("register", exact: true)
        end

        it "I don't see the login or register message if I'm already logged in" do
          user = create(:user)
          login_as(user)

          visit item_path(@item_1)
          click_on "Add to Shopping Cart"
          click_on "Cart"

          expect(page).to_not have_content("You must login or register to checkout.")
          expect(page).to_not have_link("login")
          expect(page).to_not have_link("register")

        end

        it "I don't see the login or register message if I don't have items in my cart" do
          visit cart_path
          expect(page).to_not have_content("You must login or register to checkout.")
          expect(page).to_not have_link("login")
          expect(page).to_not have_link("register")
        end

        it "in the flash message, login is a path to login and register to register" do
          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          click_on "Cart"

          click_link("login")
          expect(current_path).to eq(login_path)

          click_on "Cart"

          expect(current_path).to eq(cart_path)
          click_on("register")

          expect(current_path).to eq(register_path)

          click_on "Cart"

          expect(page).to have_content("You must login or register to checkout.")
        end

        it 'I can click a button to remove all items from my cart' do
          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          visit item_path(@item_2)
          click_on "Add to Shopping Cart"

          click_on 'Cart'

          within "#item-#{@item_1.id}" do
            expect(page).to have_content("Quantity: 2")
          end

          click_button "Empty Cart"

          expect(page).to have_content("Your cart is empty.")
          expect(page).to have_content("Cart: 0")
          expect(page).to_not have_button("Empty Cart")

          expect(page).to_not have_css "#item-#{@item_1.id}"
          expect(page).to_not have_css "#item-#{@item_2.id}"
        end

        it 'I can remove a single item entirely from my cart' do
          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          visit item_path(@item_2)
          click_on "Add to Shopping Cart"

          click_on 'Cart'

          within "#item-#{@item_1.id}" do
            click_button 'Remove Item'
          end

          expect(page).to_not have_css "#item-#{@item_1.id}"
          expect(page).to have_css "#item-#{@item_2.id}"
        end

        it 'I see a button to increment the quantity of an item in my cart' do
          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          click_on 'Cart'

          within "#item-#{@item_1.id}" do
            click_button 'Increase Quantity'
          end

          within "#item-#{@item_1.id}" do
            expect(page).to have_content("Quantity: 2")
          end
        end

        it 'I cannot increment the quantity of an item beyond current stock' do
          visit item_path(@item_1)
          click_on "Add to Shopping Cart"
          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          click_on 'Cart'

          within "#item-#{@item_1.id}" do
            expect(page).to_not have_button('Increase Quantity')
          end
        end

        it 'I see a button to decrement the quantity of an item in my cart' do
          visit item_path(@item_1)
          click_on "Add to Shopping Cart"
          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          click_on 'Cart'

          within "#item-#{@item_1.id}" do
            click_button 'Decrease Quantity'
          end

          expect(page).to have_content("You now have 1 copy of #{@item_1.name} in your cart!")

          within "#item-#{@item_1.id}" do
            expect(page).to have_content('Quantity: 1')
          end
        end

        it 'decrementing the quantity to zero removes the item from my cart' do
          visit item_path(@item_1)
          click_on "Add to Shopping Cart"

          click_on 'Cart'

          within "#item-#{@item_1.id}" do
            click_button 'Decrease Quantity'
          end

          expect(page).to have_content("Your cart is empty.")

          expect(page).to_not have_css("#item-#{@item_1.id}")
        end
      end
    end
  end

  context 'as a registered user' do
    before :each do
      @user = create(:user)
      @merchant = create(:merchant)
      @item_1 = @merchant.items.create(name: "Thing 1", description: "It's a thing", image: "https://upload.wikimedia.org/wikipedia/en/5/53/Snoopy_Peanuts.png", price: 5.0, quantity: 1)
      @item_2 = create(:item, user: @merchant)
    end
    describe 'when my cart is empty' do
      it 'I don\'t see a button to checkout' do
        login_as(@user)
        click_link 'Cart'

        expect(page).to_not have_button('Checkout')

        visit item_path(@item_1)
        click_on "Add to Shopping Cart"
        click_link 'Cart'
        click_button 'Empty Cart'
        expect(page).to_not have_button('Checkout')
        expect(page).to_not have_button('Empty Cart')
      end
    end
    describe 'when I add items to my cart' do
      it 'and i visit my cart I can check out' do
        login_as(@user)

        visit item_path(@item_1)
        click_on "Add to Shopping Cart"

        visit item_path(@item_1)
        click_on "Add to Shopping Cart"

        visit item_path(@item_2)
        click_on "Add to Shopping Cart"

        click_on "Cart"

        expect(page).to have_button("Checkout")

        click_button "Checkout"

        expect(current_path).to eq(profile_orders_path)
        expect(page).to have_content("Your order was created!")

        expect(page).to have_content("pending")

        visit cart_path

        expect(page).to have_content("Your cart is empty.")
      end
    end
  end
end
