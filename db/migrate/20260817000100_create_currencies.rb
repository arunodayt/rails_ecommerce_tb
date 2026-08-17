class CreateCurrencies < ActiveRecord::Migration[8.1]
  def change
    create_table :currencies do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.decimal :usd_rate, precision: 18, scale: 8, null: false
      t.datetime :rate_updated_at

      t.timestamps
    end

    add_index :currencies, "upper(code)", unique: true, name: "index_currencies_on_upper_code"
  end
end
