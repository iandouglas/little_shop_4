class CouponsController < ApplicationController
  before_action :require_shopper

  def create
    coupon = Coupon.find_by_name(params[:coupon])
    if coupon && !coupon.disabled
      unless  current_user && current_user.redeemed_coupon?(coupon)
        session[:coupon] = coupon.id
        flash[:success] = "Coupon \"#{coupon.name}\" has been applied."
      else
        flash[:danger] = "Coupon \"#{coupon.name}\" has already been redeemed"
      end
    else
      flash[:warning] = "Invalid coupon name."
    end
    redirect_to cart_path
  end
end
