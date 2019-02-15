class UsersController < ApplicationController
  before_action :require_registered, only: [:show, :edit]

  def index
    @merchants = User.active_merchants
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
      errors = @user.errors.details
      if errors.has_key?(:email) && errors[:email].first[:error] == :taken
        flash[:danger] = 'That email is already registered.'
        @user.email = nil
      else
        flash[:danger] = 'The information you entered was invalid.'
      end
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
    binding.pry
    @user = current_user
    if @user.update(user_params)
      flash[:success] = "Your profile has been updated"
      redirect_to profile_path
    else
      errors = @user.errors.details
      if errors.has_key?(:email) && errors[:email].first[:error] == :taken
        flash[:danger] = "That email is already registered."
        @user.email = nil
        render :'users/edit'
      end
    end
  end

  private

  def require_registered
    render file: '/public/404' unless current_registered?
  end

  def current_registered?
    current_user && current_user.registered?
  end

  def user_params
    strong_params = params.require(:user).permit(:name, :address, :city, :state, :zipcode, :email, :password, :password_confirmation)
    strong_params.delete(:password) if strong_params[:password] == ""
    strong_params.delete(:password_confirmation) if strong_params[:password_confirmation] == ""
    strong_params
  end
end
