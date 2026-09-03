class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.integer :price_cents, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :products, :active
  end
end
