class AddSkuToProducts < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :sku, :string

    change_column_null :products, :sku, false
    add_index :products, "lower(sku)", unique: true, name: "index_products_on_lower_sku"
  end

  def down
    remove_index :products, name: "index_products_on_lower_sku"
    remove_column :products, :sku
  end
end
