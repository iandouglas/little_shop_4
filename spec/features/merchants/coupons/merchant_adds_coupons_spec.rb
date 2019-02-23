require 'rails_helper'

RSpec.describe 'Adding coupons', type: :feature do
  include ActionView::Helpers
  context 'as a merchant' do
    before :each do
      @merchant = create(:merchant)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@merchant)
    end

    it 'I can create new coupons within the system' do
      visit dashboard_coupons_path

      click_link 'Add A Coupon'

      fill_in 'coupon[name]', with: "Test1"
      fill_in 'coupon[value]', with: "25"
      page.select("Percent", from: "Discount type")
      click_button 'Submit'

      expect(current_path).to eq(dashboard_coupons_path)
      expect(page).to have_content('Coupon "TEST1" has been added to the system.')

      within "#coupon-#{Coupon.last.id}" do
        expect(page).to have_content("TEST1")
        expect(page).to have_content("25%")
        expect(page).to have_content("Active")
      end

      click_link 'Add A Coupon'

      fill_in 'coupon[name]', with: "Test2"
      fill_in 'coupon[value]', with: "10"
      page.select("Dollars", from: "Discount type")
      click_button 'Submit'

      within "#coupon-#{Coupon.last.id}" do
        expect(page).to have_content("TEST2")
        expect(page).to have_content(number_to_currency(10))
        expect(page).to have_content("Active")
      end
    end

    it 'I cannot create new coupons with bad information' do
      visit dashboard_coupons_path

      click_link 'Add A Coupon'
      click_button 'Submit'

      expect(page).to have_content("Name can't be blank")
      expect(page).to have_content("Name is too short (minimum is 1 character)")
      expect(page).to have_content("Value can't be blank")
      expect(page).to have_content("Value is not a number")
    end

    it 'I cannot create new coupons with negative values' do
      visit dashboard_coupons_path

      click_link 'Add A Coupon'

      fill_in 'coupon[name]', with: "Test2"
      fill_in 'coupon[value]', with: "-0.1"
      page.select("Dollars", from: "Discount type")
      click_button 'Submit'

      expect(page).to have_content("Value must be greater than or equal to 0")
    end

    it 'I cannot create new coupons with duplicate names' do
      existing_coupon = create(:coupon)
      visit dashboard_coupons_path

      click_link 'Add A Coupon'

      fill_in 'coupon[name]', with: existing_coupon.name
      fill_in 'coupon[value]', with: existing_coupon.value

      click_button 'Submit'

      expect(page).to have_content("Name has already been taken")
    end

    it 'I cannot create more than five coupons within the system' do
      create_list(:coupon, 5, user: @merchant)
      visit dashboard_coupons_path

      expect(page).to_not have_link 'Add A Coupon'

      visit new_dashboard_coupons_path

      expect(current_path).to eq(dashboard_coupons_path)
      expect(page).to have_content "You have met your coupon limit for the system."
    end
  end
end
