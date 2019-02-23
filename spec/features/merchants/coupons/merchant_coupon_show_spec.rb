require 'rails_helper'

RSpec.describe 'When I visit my coupon show page' do
  include ActionView::Helpers
  context 'as a merchant' do
    before :each do
      @merchant = create(:merchant)
      @unused_coupon = create(:coupon, user: @merchant)
      @inactive_coupon = create(:inactive_coupon, user: @merchant)
      @used_coupon = create(:coupon, user: @merchant, orders: [create(:order)])
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@merchant)
    end

    it 'Each coupon name on my coupon index page is a link to a show page' do
      visit dashboard_coupons_path

      click_link @unused_coupon.name

      expect(current_path).to eq(dashboard_coupon_path(@unused_coupon))
    end

    it 'I see all information about the coupon' do
      visit dashboard_coupon_path(@unused_coupon)

      expect(page).to have_content(@unused_coupon.name)
      expect(page).to have_content("Value: #{number_to_currency(@unused_coupon.value)}")
      expect(page).to have_content("Created: #{@unused_coupon.created_at.strftime("%B, %d %Y at %I:%M %p %Z")}")
      expect(page).to have_content("Last Updated: #{@unused_coupon.updated_at.strftime("%B, %d %Y at %I:%M %p %Z")}")
      expect(page).to have_content("Current Status: Active")
      expect(page).to have_link 'Edit Coupon'
    end

    it 'Enabled coupons have an option to disable them' do
      visit dashboard_coupon_path(@unused_coupon)

      expect(page).to have_button 'Disable Coupon'
      expect(page).to_not have_button 'Enable Coupon'
    end

    it 'Disabled coupons have an option to enable them' do
      visit dashboard_coupon_path(@inactive_coupon)

      expect(page).to have_button 'Enable Coupon'
      expect(page).to_not have_button 'Disable Coupon'
    end

    it 'Unused coupons have an option to delete them' do
      visit dashboard_coupon_path(@unused_coupon)

      expect(page).to have_button 'Delete Coupon'

      visit dashboard_coupon_path(@used_coupon)

      expect(page).to_not have_button 'Delete Coupon'
    end

    it "I cannot access another merchant's coupons" do
      other_merchants_coupon = create(:coupon)

      visit dashboard_coupon_path(other_merchants_coupon)

      expect(current_path).to eq(dashboard_coupons_path)
      expect(page).to have_content("The page you were looking for doesn't exist")
    end
  end
end
