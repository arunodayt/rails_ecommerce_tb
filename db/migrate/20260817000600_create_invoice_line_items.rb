class CreateInvoiceLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :product_sku, null: false
      t.string :name, null: false
      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false

      t.timestamps
    end
  end
end
