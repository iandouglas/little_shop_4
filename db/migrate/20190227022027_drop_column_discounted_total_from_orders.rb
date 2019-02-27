class DropColumnDiscountedTotalFromOrders < ActiveRecord::Migration[5.1]
  def change
    remove_column :orders, :discounted_total
  end
end
