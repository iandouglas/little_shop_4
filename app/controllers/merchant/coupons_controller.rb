class Merchant::CouponsController < Merchant::BaseController
  def index
    @coupons = current_user.coupons
  end

  def new
    @coupon = Coupon.new
  end

  def create
    @coupon = Coupon.new(coupon_params)
    @coupon.save
    redirect_to dashboard_coupons_path
  end
end
