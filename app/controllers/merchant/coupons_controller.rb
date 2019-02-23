class Merchant::CouponsController < Merchant::BaseController
  def index
    @coupons = current_user.coupons
  end

  def new
    @coupon = Coupon.new
  end

  def create
    @coupon = current_user.coupons.new(coupon_params)
    if @coupon.save
      flash[:success] = "Coupon \"#{@coupon.name}\" has been added to the system."
      redirect_to dashboard_coupons_path
    else
      flash[:danger] = "There are problems with the provided information."
      render :new
    end
  end

  private

  def coupon_params
    strong_params = params.require(:coupon).permit(:name, :value, :percent)
    strong_params[:name].upcase!
    strong_params[:percent] = strong_params[:percent] == "Percent"
    strong_params
  end
end
