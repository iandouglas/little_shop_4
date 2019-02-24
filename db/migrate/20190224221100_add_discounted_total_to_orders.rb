class AddDiscountedTotalToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :discounted_total, :float
  end
end
