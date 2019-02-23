class Merchant::CouponsController < Merchant::BaseController
  def index
    @user = current_user
    @coupons = @user.coupons
  end

  def show
    @coupon = Coupon.find(params[:id])
    unless @coupon.user == current_user
      render file: '/public/404'
    end
  end

  def new
    @coupon = Coupon.new
  end

  def create
    if current_user.coupon_count < 5
      @coupon = current_user.coupons.new(coupon_params)
      if @coupon.save
        flash[:success] = "Coupon \"#{@coupon.name}\" has been added to the system."
        redirect_to dashboard_coupons_path
      else
        flash[:danger] = "There are problems with the provided information."
        render :new
      end
    else
      flash[:danger] = "You have met your coupon limit for the system."
      redirect_to dashboard_coupons_path
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
