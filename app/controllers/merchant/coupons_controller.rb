class Merchant::CouponsController < Merchant::BaseController
  def index
    @coupons = current_user.coupons
  end
end
