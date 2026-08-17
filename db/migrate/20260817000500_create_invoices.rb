class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :order, null: false, foreign_key: true
      t.string :number
      t.string :status, null: false, default: "issued"
      t.decimal :tax_rate, precision: 5, scale: 2, null: false
      t.integer :subtotal_cents, null: false
      t.integer :tax_cents, null: false
      t.integer :total_cents, null: false
      t.datetime :issued_at, null: false
      t.string :billing_name
      t.jsonb :billing_address
      t.string :merchant_name
      t.jsonb :merchant_address

      t.timestamps
    end

    add_index :invoices, :number, unique: true
    # At most one non-void invoice per order; voided invoices are kept for the record.
    add_index :invoices, :order_id, unique: true, where: "status = 'issued'",
              name: "index_invoices_active_per_order"
  end
end
