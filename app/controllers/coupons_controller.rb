class CouponsController < ApplicationController
  before_action :require_shopper

  def create
    coupon = Coupon.find_by_name(params[:coupon])
    session[:coupon] = coupon.id
    flash[:success] = "Coupon \"#{coupon.name}\" has been applied."
    redirect_to cart_path
  end
end
