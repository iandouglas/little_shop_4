class AddDefaultValueToOrderDiscountedTotal < ActiveRecord::Migration[5.1]
  def change
    change_column_default :orders, :discounted_total, 0.0
  end
end
