class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :line1, null: false
      t.string :line2
      t.string :city, null: false
      t.string :state
      t.string :postal_code
      t.string :country, null: false
      t.boolean :default, null: false, default: false

      t.timestamps
    end

    add_index :addresses, %i[customer_id kind]
  end
end
