class OrdersController < ApplicationController
  before_action :require_user_or_admin

  def index
    @orders = Order.where(user_id: current_user.id)
  end

  def show
    @order = Order.find(params[:id])
  end

  def create
    user = User.find(current_user.id)
    order = user.orders.create
    @cart.contents.each do |item_id, quantity|
      item = Item.find(item_id)
      order.order_items.create(item: item, unit_price: item.price, quantity: quantity)
    end
    if session[:coupon]
      coupon = Coupon.find(session[:coupon])
      order.update(coupon: coupon, discounted_total: @cart.discounted_total(coupon))
      session.delete(:coupon)
    end
    @cart.contents.clear
    flash[:success] = "Your order was created!"
    redirect_to profile_orders_path
  end

  def update
    @order = Order.find(params[:id])
    @order.cancel
    flash[:danger] = "Order ##{@order.id} has been cancelled."
    redirect_to profile_path
  end
end
