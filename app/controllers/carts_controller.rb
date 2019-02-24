class CartsController < ApplicationController
  include ActionView::Helpers::TextHelper

  before_action :require_shopper

  def show
    flash[:primary] = "Your cart is empty." if @cart.total_count == 0
    if !current_user && @cart.total_count > 0
      flash[:danger] = %Q[You must <a href="/login">login</a> or <a href="/register">register</a> to checkout.].html_safe
    end
    @coupon = session[:coupon] && Coupon.find(session[:coupon])
    @items = {}
    @cart.contents.each do |item, quantity|
      @items[Item.find(item)] = quantity.to_i
    end
  end

  def create
    item = Item.find(params[:item_id])
    item_id_str = item.id.to_s
    @cart.add_item(item_id_str)
    session[:cart] = @cart.contents
    quantity = session[:cart][item_id_str]
    flash[:success] = "You now have #{pluralize(quantity, "copy")} of #{item.name} in your cart!"
    redirect_to items_path
  end

  def update
    @item = Item.find(params[:item_id])
    @item_id_str = @item.id.to_s
    @new_quantity = params[:quantity].to_i || 0
    @current_quantity = @cart.contents[@item_id_str].to_i
    adjust_quantity
    flash[:success] = "You now have #{pluralize(@new_quantity, "copy")} of #{@item.name} in your cart!"
    redirect_to cart_path
  end

  def destroy
    @cart.contents.clear
    redirect_to cart_path
  end

  private

  def adjust_quantity
    if @new_quantity > 0
      if @new_quantity < @current_quantity
        @cart.remove_item(@item_id_str)
      elsif @new_quantity <= @item.quantity
        @cart.add_item(@item_id_str)
      end
    else
      @cart.clear_item(@item_id_str)
    end
  end
end
