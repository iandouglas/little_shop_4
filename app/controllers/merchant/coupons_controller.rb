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

  def edit
    @coupon = Coupon.find(params[:id])
    unless @coupon.user == current_user
      render file: '/public/404'
    end
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

  def update
    @coupon = Coupon.find(params[:id])
    if @coupon.unused?
      if @coupon.update(coupon_params)
        flash[:success] = "Coupon \"#{@coupon.name}\" has been updated."
        redirect_to dashboard_coupon_path(@coupon)
      else
        flash[:danger] = "There are problems with the provided information."
        render :edit
      end
    else
      flash[:danger] = "Unable to update coupon. (Already redeemed)."
      redirect_to dashboard_coupon_path(@coupon)
    end
  end

  def enable
    coupon = Coupon.find(params[:id])
    coupon.update(disabled: false)
    flash[:success] = "Coupon \"#{coupon.name}\" has been enabled."
    redirect_to dashboard_coupon_path(coupon)
  end

  def disable
    coupon = Coupon.find(params[:id])
    coupon.update(disabled: true)
    flash[:warning] = "Coupon \"#{coupon.name}\" has been disabled."
    redirect_to dashboard_coupon_path(coupon)
  end

  def destroy
    coupon = Coupon.find(params[:id])
    if coupon.unused? && coupon.destroy
      flash[:danger] = "Coupon \"#{coupon.name}\" has been deleted."
    else
      flash[:warning] = "Unable to delete coupon."
    end
    redirect_to dashboard_coupons_path
  end

  private

  def coupon_params
    strong_params = params.require(:coupon).permit(:name, :value, :percent)
    strong_params[:name].upcase!
    strong_params[:percent] = strong_params[:percent] == "Percent"
    strong_params
  end
end
