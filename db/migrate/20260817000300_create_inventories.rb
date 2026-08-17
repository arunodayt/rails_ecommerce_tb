class CreateInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories do |t|
      t.references :product, null: false, foreign_key: true, index: { unique: true }
      t.integer :quantity, null: false, default: 0

      t.timestamps
    end
  end
end
