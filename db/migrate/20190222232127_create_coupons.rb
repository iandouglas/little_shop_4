class CreateCoupons < ActiveRecord::Migration[5.1]
  def change
    create_table :coupons do |t|
      t.references :user
      t.string :name
      t.boolean :percent
      t.float :value

      t.timestamps
    end
  end
end
