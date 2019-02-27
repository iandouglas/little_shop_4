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
    @order = user.orders.create
    @items = @cart.contents.map do |item_id, quantity|
      {Item.find(item_id) => quantity.to_i}
    end
    if session[:coupon]
      @coupon = Coupon.find(session[:coupon])
      @order.update(coupon: @coupon, discounted_total: @cart.discounted_total(@coupon))
      parse_coupon
      session.delete(:coupon)
    else
      make_standard_order
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

  def parse_coupon
    if @coupon.percent
      make_percentage_order
    else
      make_dollar_order
    end
  end

  def make_standard_order
    @items.each do |ordered_item|
      item = ordered_item.keys.first
      quantity = ordered_item.values.first
      @order.order_items.create(item: item, unit_price: item.price, quantity: quantity)
    end
  end

  def make_percentage_order
    @items.each do |ordered_item|
      item = ordered_item.keys.first
      quantity = ordered_item.values.first
      if item.user == @coupon.user
        if @coupon.value > 100
          @order.order_items.create(item: item, unit_price: 0, quantity: quantity)
        else
          @order.order_items.create(item: item, unit_price: item.price * (1 - (@coupon.value / 100)), quantity: quantity)
        end
      else
        @order.order_items.create(item: item, unit_price: item.price, quantity: quantity)
      end
    end
  end

  def make_dollar_order
    remaining_value = @coupon.value
    @items.each do |ordered_item|
      item = ordered_item.keys.first
      quantity = ordered_item.values.first
      if item.user == @coupon.user
        if item.price * quantity > remaining_value
          @order.order_items.create(item: item, unit_price: item.price - (remaining_value / quantity), quantity: quantity)
        else
          remaining_value -= item.price * quantity
          @order.order_items.create(item: item, unit_price: 0, quantity: quantity)
        end
      else
        @order.order_items.create(item: item, unit_price: item.price, quantity: quantity)
      end
    end
  end
end
