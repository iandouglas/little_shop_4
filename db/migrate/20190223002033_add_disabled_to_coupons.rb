class AddDisabledToCoupons < ActiveRecord::Migration[5.1]
  def change
    add_column :coupons, :disabled, :boolean, default: false
  end
end
