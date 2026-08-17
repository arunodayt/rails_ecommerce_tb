# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if Rails.env.development?
  username = ENV.fetch("SEED_USERNAME", "admin")
  password = ENV.fetch("SEED_PASSWORD", "password123")

  user = User.find_by_username(username) || User.new(username: username)
  user.password = password
  user.role = :admin
  user.save!

  puts "Seeded user '#{user.username}' (role: #{user.role}, password: '#{password}')"
end

# Currencies are reference data required in every environment. Rates come from
# the (mocked) provider.
CURRENCY_NAMES = {
  "USD" => "US Dollar",
  "EUR" => "Euro",
  "GBP" => "British Pound",
  "INR" => "Indian Rupee",
  "JPY" => "Japanese Yen"
}.freeze

ExchangeRateProvider::MOCK_USD_RATES.each do |code, rate|
  currency = Currency.find_by_code(code) || Currency.new(code: code)
  currency.assign_attributes(name: CURRENCY_NAMES.fetch(code, code), usd_rate: rate, rate_updated_at: Time.current)
  currency.save!
end

puts "Seeded #{Currency.count} currencies"

# In development, seed a sample catalog and customer list so the API can be
# exercised with realistic data.
if Rails.env.development?
  products = [
    { sku: "WIDGET-002", name: "Deluxe Widget",     description: "Premium widget with extras",    price_cents: 1899, active: true },
    { sku: "GADGET-002", name: "Pro Gadget",        description: "Professional-grade gadget",      price_cents: 4999, active: true },
    { sku: "CABLE-001",  name: "USB-C Cable 1m",    description: "Braided USB-C charging cable",   price_cents: 999,  active: true },
    { sku: "CABLE-002",  name: "USB-C Cable 2m",    description: "Braided USB-C charging cable",   price_cents: 1299, active: true },
    { sku: "ADAPT-001",  name: "65W Power Adapter", description: "GaN fast-charge adapter",        price_cents: 3499, active: true },
    { sku: "CASE-001",   name: "Carry Case",        description: "Padded protective case",         price_cents: 2499, active: true },
    { sku: "MOUNT-001",  name: "Desk Mount",        description: "Adjustable aluminum desk mount", price_cents: 5999, active: true },
    { sku: "STAND-OLD",  name: "Legacy Stand",      description: "Discontinued model",             price_cents: 1500, active: false }
  ]

  products.each do |attrs|
    product = Product.find_or_initialize_by(sku: attrs[:sku])
    product.assign_attributes(attrs)
    product.save!
  end

  puts "Seeded #{products.size} products (#{Product.count} total in catalog)"

  # Stock every product once so the seeded orders below can deduct inventory.
  # Only sets quantity on creation so manual dev adjustments survive reruns.
  Product.find_each do |product|
    Inventory.find_or_create_by!(product: product) { |inventory| inventory.quantity = 100 }
  end

  puts "Seeded inventory for #{Inventory.count} products"

  customers = [
    { name: "Alice Johnson", email: "alice.johnson@example.com" },
    { name: "Bob Martinez",  email: "bob.martinez@example.com" },
    { name: "Carol Nguyen",  email: "carol.nguyen@example.com" },
    { name: "David Okafor",  email: "david.okafor@example.com" },
    { name: "Emma Larsson",  email: "emma.larsson@example.com" },
    { name: "Frank Chen",    email: "frank.chen@example.com" }
  ]

  customers.each do |attrs|
    customer = Customer.find_by_email(attrs[:email]) || Customer.new
    customer.assign_attributes(attrs)
    customer.save!
  end

  puts "Seeded #{customers.size} customers (#{Customer.count} total)"

  # Sample orders. Unlike products/customers, orders have no unique to match
  # so this block only runs when the orders table is empty — that
  # keeps db:seed safe to rerun without piling up duplicate orders. Totals and
  # per-line unit prices are derived by the model from the products above.
  if Order.none?
    find_product = ->(sku) { Product.where("lower(sku) = ?", sku.downcase).first! }

    order_specs = [
      ["alice.johnson@example.com", "paid",      [["WIDGET-002", 2], ["CABLE-001", 1]]],
      ["alice.johnson@example.com", "shipped",   [["ADAPT-001", 1]]],
      ["bob.martinez@example.com",  "pending",   [["GADGET-002", 1], ["CASE-001", 1], ["MOUNT-001", 1]]],
      ["bob.martinez@example.com",  "paid",      [["CABLE-002", 3]]],
      ["carol.nguyen@example.com",  "shipped",   [["WIDGET-002", 1], ["GADGET-002", 1]]],
      ["carol.nguyen@example.com",  "refunded",  [["CASE-001", 2], ["CABLE-001", 2], ["ADAPT-001", 1]]],
      ["david.okafor@example.com",  "paid",      [["MOUNT-001", 1], ["ADAPT-001", 1]]],
      ["david.okafor@example.com",  "cancelled", [["GADGET-002", 2]]],
      ["emma.larsson@example.com",  "pending",   [["CABLE-001", 4], ["CABLE-002", 2]]],
      ["emma.larsson@example.com",  "paid",      [["WIDGET-002", 1], ["CASE-001", 1], ["MOUNT-001", 2], ["ADAPT-001", 1]]],
      ["frank.chen@example.com",    "shipped",   [["GADGET-002", 1]]],
      ["frank.chen@example.com",    "paid",      [["WIDGET-002", 3], ["CABLE-002", 1]]]
    ]

    order_specs.each do |email, status, lines|
      order = Order.new(customer: Customer.find_by_email!(email), status: status)
      lines.each { |sku, qty| order.order_items.build(product: find_product.call(sku), quantity: qty) }
      order.save!
    end

    puts "Seeded #{order_specs.size} orders (#{Order.count} total)"
  else
    puts "Skipped order seeding (#{Order.count} order(s) already present)"
  end
end
