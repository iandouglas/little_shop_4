class UsersController < ApplicationController
  before_action :require_registered, only: [:show, :edit, :update]

  def index
    @merchants = User.all_merchants
    @top_merchants_by_revenue = User.top_merchants_by_revenue
    @fastest_merchants = User.fastest_merchants
    @slowest_merchants = User.slowest_merchants
    @top_states = Order.top_states
    @top_cities = Order.top_cities
    @biggest_orders = Order.biggest_orders
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id
      flash[:success] = 'You are now registered and logged in!'
      redirect_to profile_path
    else
      flash[:danger] = @user.errors.full_messages
      render :new
    end
  end

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      flash[:success] = "Your profile has been updated"
      redirect_to profile_path
    else
      errors = @user.errors.details
      if errors.has_key?(:email) && errors[:email].first[:error] == :taken
        flash[:danger] = "That email is already registered."
        @user.email = nil
      end
      render :'users/edit'
    end
  end

  private

  def user_params
    strong_params = params.require(:user).permit(:name, :address, :city, :state, :zipcode, :email, :password, :password_confirmation)
    strong_params.delete(:password) if strong_params[:password] == ""
    strong_params.delete(:password_confirmation) if strong_params[:password_confirmation] == ""
    strong_params
  end
end
