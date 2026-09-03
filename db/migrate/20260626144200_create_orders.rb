class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.integer :total_cents, null: false, default: 0

      t.timestamps
    end

    add_index :orders, :status
  end
end
