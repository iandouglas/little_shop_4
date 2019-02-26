class User < ApplicationRecord
  has_many :orders
  has_many :items
  has_many :coupons

  has_secure_password

  enum role: ['registered', 'merchant', 'admin']

  validates :name,
    presence: true,
    length: {minimum: 1}

  validates :city,
    presence: true,
    length: {minimum: 1}

  validates :password,
    confirmation: true

  validates :address,
    presence: true,
    length: {minimum: 1}

  validates :email,
    presence: true,
    length: {minimum: 1},
    uniqueness: true

  validates :state,
    presence: true

  validates :zipcode,
    presence: true,
    numericality: {
      only_integer: true
  }


  def self.fastest_merchants
    joins(items: :order_items)
   .select('users.*, avg(order_items.updated_at - order_items.created_at) as fulfillment_time')
   .where(order_items: {fulfilled: true}, disabled: false)
   .group(:id)
   .order('fulfillment_time asc')
   .limit(3)
  end

  def self.slowest_merchants
    joins(items: :order_items)
   .select('users.*, avg(order_items.updated_at - order_items.created_at) as fulfillment_time')
   .where(order_items: {fulfilled: true}, disabled: false)
   .group(:id)
   .order('fulfillment_time desc')
   .limit(3)
  end

  def self.top_merchants_by_revenue
    joins(items: :order_items)
   .select("users.*, sum(order_items.unit_price*order_items.quantity) as revenue")
   .where(order_items: {fulfilled: true}, role: 1, disabled: false)
   .group(:id)
   .order("revenue desc")
   .limit(3)
  end

  def self.total_sales_by_merchant
    joins(items: :orders)
    .select('users.*, sum(order_items.unit_price * order_items.quantity) as revenue')
    .where(orders: {status: 'completed'})
    .group(:id)
    .order('revenue desc')
  end

  def coupon_count
    coupons.count
  end

  def redeemed_coupon?(coupon)
    orders.find_by(coupon: coupon).instance_of?(Order)
  end

  def top_items_for_merchant(limit)
    items.joins(:order_items)
         .where(order_items: { fulfilled: true })
         .select('items.*, sum(order_items.quantity) as total_quantity')
         .group(:id)
         .order('total_quantity desc')
         .limit(limit)
  end

  def items_sold_by_quantity
    items.joins(:order_items)
         .where(order_items: { fulfilled: true })
         .sum('order_items.quantity')
  end

  def items_sold_by_percentage
    items_sold = items_sold_by_quantity
    total_stock = items.sum(:quantity)
    items_sold.to_f / (items_sold + total_stock)
  end

  def top_states(limit)
    items.joins(orders: :user)
         .select('sum(order_items.quantity) as state_quantity, users.state')
         .where(order_items: { fulfilled: true })
         .group('users.state')
         .order('state_quantity desc')
         .limit(limit)
  end

  def top_cities(limit)
    items.joins(orders: :user)
         .select("sum(order_items.quantity) as city_quantity, concat(users.city, ', ', users.state) as location")
         .where(order_items: { fulfilled: true })
         .group('location')
         .order('city_quantity desc')
         .limit(limit)
  end

  def top_customer_by_orders
    items.joins(orders: :user)
         .select('users.id, users.name, count(distinct orders.id) as order_count')
         .where(order_items: { fulfilled: true })
         .group('users.id')
         .order('order_count desc')
         .first
  end

  def top_customer_by_items
    items.joins(orders: :user)
         .select('users.id, users.name, sum(order_items.quantity) as item_count')
         .where(order_items: { fulfilled: true })
         .group('users.id')
         .order('item_count desc')
         .first
  end

  def top_spenders(limit)
    items.joins(orders: :user)
         .select('users.id, users.name, sum(order_items.quantity * order_items.unit_price) as total_spent')
         .where(order_items: { fulfilled: true })
         .group('users.id')
         .order('total_spent desc')
         .limit(limit)
  end

  def revenue_by_month(limit)
    items.joins(:order_items)
         .select("SUM(order_items.unit_price * order_items.quantity) AS revenue,
                  EXTRACT(MONTH FROM order_items.created_at) AS month,
                  EXTRACT(YEAR FROM order_items.created_at) AS year")
         .where("order_items.created_at > ?", limit.months.ago)
         .where(order_items: {fulfilled: true})
         .group("year, month")
         .order('year desc, month desc')
  end

  def current_inventory
    items.sum(:quantity)
  end

  def self.all_merchants
    where(role: 1)
    .order(id: :asc) # Was getting unstable returns, updated for tests
  end
end
