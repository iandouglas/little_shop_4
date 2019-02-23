require 'rails_helper'

RSpec.describe 'When I visit the coupon index page', type: :feature do
  context 'as a merchant' do
    before :each do
      @merchant = create(:merchant)
      @coupon_1 = create(:coupon)
      @coupon_1 = create(:percentage_coupon)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@merchant)
    end
    it 'I see a link on my dashboard to manage my coupons that takes me to my coupons page' do
      visit dashboard_path

      click_link 'Manage My Coupons'

      expect(current_path).to eq(dashboard_coupons_path)
    end

    it 'I see a link to add new coupons to the system' do
      visit dashboard_coupons_path

      expect(page).to have_link 'Add A Coupon'
    end

    it 'I see all information about the coupons I have in the system currently' do
      visit dashboard_coupons_path

      within "#coupon-#{@coupon_1.id}" do
        expect(page).to have_content(@coupon_1.name)
        expect(page).to have_content("#{@coupon_1.value}%")
        expect(page).to have_content(@coupon_1.created_at.strftime("%B, %d %Y at %I:%M %p %Z"))
        expect(page).to have_content(@coupon_1.updated_at.strftime("%B, %d %Y at %I:%M %p %Z"))
        expect(page).to have_content("Active")
      end

      within "#coupon-#{@coupon_2.id}" do
        expect(page).to have_content(@coupon_2.name)
        expect(page).to have_content(number_to_currency(@coupon_2.value))
        expect(page).to have_content(@coupon_2.created_at.strftime("%B, %d %Y at %I:%M %p %Z"))
        expect(page).to have_content(@coupon_2.updated_at.strftime("%B, %d %Y at %I:%M %p %Z"))
        expect(page).to have_content("Active")
      end
    end
  end
end
