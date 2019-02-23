require 'rails_helper'

RSpec.describe 'Editing coupons', type: :feature do
  include ActionView::Helpers
  context 'as a merchant' do
    before :each do
      @merchant = create(:merchant)
      @coupon = create(:coupon, user: @merchant)
      @percentage_coupon = create(:percentage_coupon, user: @merchant)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@merchant)
    end

    it 'I see my coupons information prepopulated in the edit form' do
      visit dashboard_coupon_path(@coupon)

      click_link 'Edit Coupon'

      expect(page).to have_content(@coupon.name)
      expect(page).to have_content(@coupon.value)
      expect(page).to have_select('Discount Type', selected: 'Dollars')

      visit edit_dashboard_coupon_path(@percentage_coupon)

      expect(page).to have_content(@percentage_coupon.name)
      expect(page).to have_content(@percentage_coupon.value)
      expect(page).to have_select('Discount Type', selected: 'Percent')
    end

    it 'I cannot create new coupons with bad information' do
      visit edit_dashboard_coupon_path(@coupon)

      fill_in 'coupon[name]', with: ''
      fill_in 'coupon[value]', with: ''
      click_button 'Submit'

      expect(page).to have_content("Name can't be blank")
      expect(page).to have_content("Name is too short (minimum is 1 character)")
      expect(page).to have_content("Value can't be blank")
      expect(page).to have_content("Value is not a number")
    end

    it 'I cannot create new coupons with negative values' do
      visit edit_dashboard_coupon_path(@coupon)

      fill_in 'coupon[value]', with: "-0.1"
      click_button 'Submit'

      expect(page).to have_content("Value must be greater than or equal to 0")
    end

    it 'I cannot create new coupons with duplicate names' do
      visit edit_dashboard_coupon_path(@coupon)

      fill_in 'coupon[name]', with: @percentage_coupon.name

      click_button 'Submit'

      expect(page).to have_content("Name has already been taken")
    end

    it 'I cannot manually navigate to the edit path for another merchants coupons' do
      other_merchant_coupon = create(:coupon)

      visit edit_dashboard_coupon_path(other_merchant_coupon)

      expect(page).to have_content("The page you were looking for doesn't exist")
    end
  end
end
