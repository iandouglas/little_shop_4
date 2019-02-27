class Order < ApplicationRecord
  belongs_to :user
  belongs_to :coupon, required: false
  has_many :order_items
  has_many :items, through: :order_items

  validates_presence_of :status

  enum status: ['pending', 'processing', 'completed', 'cancelled']

  def total_items_for_merchant(merchant)
    order_items.joins(:item)
               .where(items: { user: merchant })
               .sum(:quantity)
  end

  def total_value_for_merchant(merchant)
    order_items.joins(:item)
               .where(items: { user: merchant })
               .sum('(order_items.quantity * order_items.unit_price)')
  end

  def self.top_states
    joins(:user)
    .select('users.state, count(orders.id) as order_count')
    .where(status: 'completed')
    .group('users.state')
    .order('order_count desc')
    .limit(3)
  end

  def self.top_cities(limit=3)
     joins(:user)
     .select("count(orders.id) as city_quantity, concat(users.city, ', ', users.state) as location")
     .where(status: 'completed')
     .group('location')
     .order('city_quantity desc')
     .limit(limit)
  end

  def self.biggest_orders(limit = 3)
    joins(:order_items)
    .select('sum(order_items.quantity) as total_quantity, orders.id')
    .where(status: 'completed')
    .group(:id)
    .order('total_quantity desc')
    .limit(limit)

  end

  def self.pending_orders(merchant)
    self.joins(:items)
        .where(status: 'pending', items: { user: merchant })
        .group(:id)
  end

  def quantity_of_items
    order_items.sum(:quantity)
  end

  def ordered_items
    order_items.joins(:item)
               .select("order_items.*,
                        items.name as name,
                        items.description as description,
                        items.image as image,
                        items.quantity as merchant_stock,
                        items.user_id as merchant_id")
  end

  def grand_total
    order_items.select("SUM(order_items.unit_price*order_items.quantity) as price_per_item, order_items.order_id")
              .group(:order_id)[0].price_per_item
  end

  def cancel
    self.update(status: 'cancelled')
    self.order_items.where(fulfilled: true).each do |order_item|
      item = Item.find(order_item.item_id)
      item.update(quantity: (order_item.quantity + item.quantity))
      order_item.update(fulfilled: false)
    end
  end
end
