class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency_code, null: false, default: "USD"
      t.decimal :exchange_rate, precision: 18, scale: 8, null: false
      t.integer :amount_usd_cents, null: false
      t.string :payment_method, null: false
      t.string :reference
      t.text :notes
      t.datetime :paid_at, null: false

      t.timestamps
    end
  end
end
