# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Layout:
#   1. Users (dev only)        — one login per role: admin, manager, member
#   2. Currencies (all envs)   — reference data, provider rates where available
#   3. Catalog (dev only)      — 50 products with per-product inventory
#   4. Customers (dev only)    — 10 customers, several with addresses
#   5. Orders (dev only)       — 22 orders across all statuses
#   6. Payments (dev only)     — full and installment payments in mixed currencies
#   7. Invoices (dev only)     — issued (and one voided) invoices for some orders

if Rails.env.development? || Rails.env.dev?
  users = [
    { username: ENV.fetch("SEED_USERNAME", "admin"), password: ENV.fetch("SEED_PASSWORD", "password123"), role: :admin },
    { username: "manager", password: "password123", role: :manager },
    { username: "member",  password: "password123", role: :member }
  ]

  users.each do |attrs|
    user = User.find_by_username(attrs[:username]) || User.new(username: attrs[:username])
    user.password = attrs[:password]
    user.role = attrs[:role]
    user.save!

    puts "Seeded user '#{user.username}' (role: #{user.role}, password: '#{attrs[:password]}')"
  end
end

# Currencies are reference data required in every environment. Rates come from
# the (mocked) provider where it knows the code; the rest carry seed rates and
# can be refreshed once the provider learns them.
CURRENCIES = {
  "USD" => ["US Dollar",         1.0],
  "EUR" => ["Euro",              1.08],
  "GBP" => ["British Pound",     1.27],
  "INR" => ["Indian Rupee",      0.0105],
  "JPY" => ["Japanese Yen",      0.0067],
  "AUD" => ["Australian Dollar", 0.65],
  "CAD" => ["Canadian Dollar",   0.73],
  "CHF" => ["Swiss Franc",       1.12],
  "CNY" => ["Chinese Yuan",      0.14],
  "SGD" => ["Singapore Dollar",  0.74],
  "AED" => ["UAE Dirham",        0.27]
}.freeze

CURRENCIES.each do |code, (name, seed_rate)|
  rate = ExchangeRateProvider::MOCK_USD_RATES.fetch(code, seed_rate)
  currency = Currency.find_by_code(code) || Currency.new(code: code)
  currency.assign_attributes(name: name, usd_rate: rate, rate_updated_at: Time.current)
  currency.save!
end

puts "Seeded #{Currency.count} currencies"

# In development, seed a sample catalog, customer list, orders, payments and
# invoices so the API can be exercised with realistic data.
if Rails.env.development? || Rails.env.dev?
  products = [
    { sku: "WIDGET-001", name: "Classic Widget",              description: "The original everyday widget",       price_cents: 1299,  active: true },
    { sku: "WIDGET-002", name: "Deluxe Widget",               description: "Premium widget with extras",          price_cents: 1899,  active: true },
    { sku: "WIDGET-003", name: "Widget Mini",                 description: "Pocket-sized widget",                 price_cents: 899,   active: true },
    { sku: "GADGET-001", name: "Everyday Gadget",             description: "Reliable entry-level gadget",         price_cents: 2999,  active: true },
    { sku: "GADGET-002", name: "Pro Gadget",                  description: "Professional-grade gadget",           price_cents: 4999,  active: true },
    { sku: "GADGET-003", name: "Gadget Max",                  description: "Flagship gadget, all options",        price_cents: 7999,  active: true },
    { sku: "CABLE-001",  name: "USB-C Cable 1m",              description: "Braided USB-C charging cable",        price_cents: 999,   active: true },
    { sku: "CABLE-002",  name: "USB-C Cable 2m",              description: "Braided USB-C charging cable",        price_cents: 1299,  active: true },
    { sku: "CABLE-003",  name: "USB-C to HDMI Cable",         description: "4K60 video-out cable, 2m",            price_cents: 1999,  active: true },
    { sku: "CABLE-004",  name: "Lightning Cable 1m",          description: "MFi-certified charging cable",        price_cents: 1499,  active: true },
    { sku: "CABLE-005",  name: "Ethernet Cable 5m",           description: "Cat-6 flat network cable",            price_cents: 1099,  active: true },
    { sku: "ADAPT-001",  name: "65W Power Adapter",           description: "GaN fast-charge adapter",             price_cents: 3499,  active: true },
    { sku: "ADAPT-002",  name: "100W Power Adapter",          description: "Dual-port GaN adapter",               price_cents: 4999,  active: true },
    { sku: "ADAPT-003",  name: "Travel Adapter Kit",          description: "Universal plug kit, 150+ countries",  price_cents: 2799,  active: true },
    { sku: "CASE-001",   name: "Carry Case",                  description: "Padded protective case",              price_cents: 2499,  active: true },
    { sku: "CASE-002",   name: "Hardshell Case",              description: "Crush-proof polycarbonate shell",     price_cents: 3999,  active: true },
    { sku: "CASE-003",   name: "Laptop Sleeve 13\"",          description: "Slim felt sleeve",                    price_cents: 1899,  active: true },
    { sku: "MOUNT-001",  name: "Desk Mount",                  description: "Adjustable aluminum desk mount",      price_cents: 5999,  active: true },
    { sku: "MOUNT-002",  name: "Dual Monitor Arm",            description: "Gas-spring arm for two displays",     price_cents: 10999, active: true },
    { sku: "MOUNT-003",  name: "Wall Mount",                  description: "Tilting VESA wall mount",             price_cents: 3499,  active: true },
    { sku: "STAND-001",  name: "Laptop Stand",                description: "Ergonomic aluminum riser",            price_cents: 4499,  active: true },
    { sku: "STAND-002",  name: "Tablet Stand",                description: "Foldable multi-angle stand",          price_cents: 2299,  active: true },
    { sku: "STAND-OLD",  name: "Legacy Stand",                description: "Discontinued model",                  price_cents: 1500,  active: false },
    { sku: "KEYB-001",   name: "Mechanical Keyboard",         description: "Hot-swappable, tactile switches",     price_cents: 8999,  active: true },
    { sku: "KEYB-002",   name: "Wireless Keyboard",           description: "Low-profile multi-device keyboard",   price_cents: 4999,  active: true },
    { sku: "KEYB-003",   name: "Compact 60% Keyboard",        description: "Travel-friendly mechanical board",    price_cents: 6499,  active: true },
    { sku: "MOUSE-001",  name: "Wireless Mouse",              description: "Silent-click ambidextrous mouse",     price_cents: 2999,  active: true },
    { sku: "MOUSE-002",  name: "Ergonomic Mouse",             description: "Vertical grip, 6 buttons",            price_cents: 4499,  active: true },
    { sku: "HEAD-001",   name: "Wired Headset",               description: "On-ear headset with boom mic",        price_cents: 3999,  active: true },
    { sku: "HEAD-002",   name: "Bluetooth Headphones",        description: "40h battery over-ear headphones",     price_cents: 8999,  active: true },
    { sku: "HEAD-003",   name: "Noise-Cancelling Headphones", description: "Hybrid ANC, wired and wireless",      price_cents: 15999, active: true },
    { sku: "CAM-001",    name: "1080p Webcam",                description: "Auto-focus webcam with privacy flap", price_cents: 4999,  active: true },
    { sku: "CAM-002",    name: "4K Webcam",                   description: "HDR webcam with AI framing",          price_cents: 11999, active: true },
    { sku: "HUB-001",    name: "4-Port USB Hub",              description: "Slim USB-A 3.0 hub",                  price_cents: 2499,  active: true },
    { sku: "HUB-002",    name: "7-in-1 USB-C Hub",            description: "HDMI, card reader, PD pass-through",  price_cents: 5499,  active: true },
    { sku: "HUB-003",    name: "Thunderbolt Dock",            description: "Dual-4K dock, 96W charging",          price_cents: 21999, active: true },
    { sku: "SSD-001",    name: "Portable SSD 512GB",          description: "USB-C pocket SSD, 1050MB/s",          price_cents: 7999,  active: true },
    { sku: "SSD-002",    name: "Portable SSD 1TB",            description: "USB-C pocket SSD, 1050MB/s",          price_cents: 12999, active: true },
    { sku: "HDD-001",    name: "External HDD 2TB",            description: "Desktop backup drive",                price_cents: 8499,  active: true },
    { sku: "BATT-001",   name: "Power Bank 10000mAh",         description: "Slim 20W power bank",                 price_cents: 3499,  active: true },
    { sku: "BATT-002",   name: "Power Bank 20000mAh",         description: "65W laptop-capable power bank",       price_cents: 5499,  active: true },
    { sku: "LIGHT-001",  name: "Ring Light",                  description: "10\" bi-color ring light with tripod", price_cents: 3999, active: true },
    { sku: "LIGHT-002",  name: "LED Desk Lamp",               description: "Eye-care lamp with USB charging",     price_cents: 4599,  active: true },
    { sku: "MAT-001",    name: "Desk Mat Large",              description: "900x400mm vegan leather mat",         price_cents: 2199,  active: true },
    { sku: "MAT-002",    name: "Mouse Pad",                   description: "Stitched-edge cloth pad",             price_cents: 999,   active: true },
    { sku: "SPK-001",    name: "Bluetooth Speaker",           description: "IPX7 portable speaker",               price_cents: 6999,  active: true },
    { sku: "SPK-002",    name: "Soundbar Mini",               description: "Compact desk soundbar",               price_cents: 9999,  active: true },
    { sku: "MIC-001",    name: "USB Microphone",              description: "Cardioid condenser mic",              price_cents: 8999,  active: true },
    { sku: "MIC-002",    name: "Lavalier Microphone",         description: "Clip-on mic with 3m lead",            price_cents: 2999,  active: true },
    { sku: "CHRG-OLD",   name: "Legacy Charger 30W",          description: "Discontinued wall charger",           price_cents: 1999,  active: false }
  ]

  products.each do |attrs|
    product = Product.find_or_initialize_by(sku: attrs[:sku])
    product.assign_attributes(attrs)
    product.save!
  end

  puts "Seeded #{products.size} products (#{Product.count} total in catalog)"

  # Stock every product so the seeded orders below can deduct inventory. A few
  # products are deliberately out of stock (and are never referenced by orders,
  # since order creation would fail on insufficient inventory). Quantity is only
  # set on creation so manual dev adjustments survive reruns.
  out_of_stock = ["STAND-OLD", "CHRG-OLD", "HUB-003", "CAM-002"]
  low_stock    = { "SSD-002" => 6, "HEAD-003" => 4, "MIC-001" => 9 }

  Product.find_each do |product|
    Inventory.find_or_create_by!(product: product) do |inventory|
      inventory.quantity =
        if out_of_stock.include?(product.sku) then 0
        else low_stock.fetch(product.sku, 120)
        end
    end
  end

  puts "Seeded inventory for #{Inventory.count} products (#{out_of_stock.size} out of stock)"

  customers = [
    { name: "Alice Johnson",  email: "alice.johnson@example.com" },
    { name: "Bob Martinez",   email: "bob.martinez@example.com" },
    { name: "Carol Nguyen",   email: "carol.nguyen@example.com" },
    { name: "David Okafor",   email: "david.okafor@example.com" },
    { name: "Emma Larsson",   email: "emma.larsson@example.com" },
    { name: "Frank Chen",     email: "frank.chen@example.com" },
    { name: "Grace Kim",      email: "grace.kim@example.com" },
    { name: "Hassan Ali",     email: "hassan.ali@example.com" },
    { name: "Isabella Rossi", email: "isabella.rossi@example.com" },
    { name: "James Wright",   email: "james.wright@example.com" }
  ]

  customers.each do |attrs|
    customer = Customer.find_by_email(attrs[:email]) || Customer.new
    customer.assign_attributes(attrs)
    customer.save!
  end

  puts "Seeded #{customers.size} customers (#{Customer.count} total)"

  # Addresses for some (not all) customers. Alice and Grace have both a billing
  # and a shipping address; addresses have no natural unique key, so each
  # customer's set is only created when they have none yet.
  address_book = {
    "alice.johnson@example.com" => [
      { kind: "billing",  line1: "12 Rosewood Ave",                 city: "Portland",  state: "OR", postal_code: "97201",  country: "US", default: true },
      { kind: "shipping", line1: "88 Alder St", line2: "Apt 4B",    city: "Portland",  state: "OR", postal_code: "97205",  country: "US", default: true }
    ],
    "bob.martinez@example.com" => [
      { kind: "billing",  line1: "450 Congress Ave", line2: "Ste 9", city: "Austin",   state: "TX", postal_code: "78701",  country: "US", default: true }
    ],
    "carol.nguyen@example.com" => [
      { kind: "shipping", line1: "2200 Yonge St",                   city: "Toronto",   state: "ON", postal_code: "M4S 2C6", country: "CA", default: true }
    ],
    "david.okafor@example.com" => [
      { kind: "billing",  line1: "14 Adeola Odeku St",              city: "Lagos",                                          country: "NG", default: true }
    ],
    "grace.kim@example.com" => [
      { kind: "billing",  line1: "27 Teheran-ro",                   city: "Seoul",                  postal_code: "06236",   country: "KR", default: true },
      { kind: "shipping", line1: "5 Hangang-daero",                 city: "Seoul",                  postal_code: "04382",   country: "KR", default: true }
    ]
  }

  address_book.each do |email, entries|
    customer = Customer.find_by_email!(email)
    next if customer.addresses.any?

    entries.each { |attrs| customer.addresses.create!(attrs) }
  end

  puts "Seeded addresses for #{address_book.size} customers (#{Address.count} total)"

  # Sample orders, payments and invoices. Orders have no unique key to match
  # on, so this whole block only runs when the orders table is empty — that
  # keeps db:seed safe to rerun without piling up duplicates. Totals and
  # per-line unit prices are derived by the model from the products above, and
  # each order deducts from the inventory seeded above.
  if Order.none?
    products_by_sku = Product.all.index_by(&:sku)

    # [customer email, status, created days ago, [[sku, quantity], ...]]
    order_specs = [
      ["alice.johnson@example.com",  "paid",      45, [["WIDGET-002", 2], ["CABLE-001", 1]]],
      ["alice.johnson@example.com",  "shipped",   30, [["ADAPT-001", 1], ["MAT-001", 1]]],
      ["alice.johnson@example.com",  "pending",    2, [["KEYB-001", 1]]],
      ["bob.martinez@example.com",   "pending",   20, [["GADGET-002", 1], ["CASE-001", 1], ["MOUNT-001", 1]]],
      ["bob.martinez@example.com",   "paid",      15, [["CABLE-002", 3]]],
      ["carol.nguyen@example.com",   "shipped",   28, [["WIDGET-002", 1], ["GADGET-003", 1]]],
      ["carol.nguyen@example.com",   "refunded",  50, [["CASE-001", 2], ["CABLE-001", 2], ["ADAPT-001", 1]]],
      ["david.okafor@example.com",   "paid",      12, [["MOUNT-002", 1], ["ADAPT-002", 1]]],
      ["david.okafor@example.com",   "cancelled", 33, [["GADGET-002", 2]]],
      ["emma.larsson@example.com",   "pending",    5, [["CABLE-005", 4], ["CABLE-002", 2]]],
      ["emma.larsson@example.com",   "paid",       9, [["WIDGET-001", 1], ["CASE-002", 1], ["MOUNT-001", 1]]],
      ["frank.chen@example.com",     "shipped",   25, [["HEAD-003", 1]]],
      ["frank.chen@example.com",     "paid",       7, [["WIDGET-003", 3], ["CABLE-004", 1]]],
      ["grace.kim@example.com",      "paid",      14, [["SSD-001", 1], ["HUB-002", 1]]],
      ["grace.kim@example.com",      "shipped",   40, [["CAM-001", 1], ["LIGHT-001", 1]]],
      ["hassan.ali@example.com",     "paid",      10, [["BATT-002", 2]]],
      ["hassan.ali@example.com",     "pending",    1, [["SPK-001", 1], ["MAT-002", 2]]],
      ["isabella.rossi@example.com", "paid",      18, [["MOUSE-002", 1], ["KEYB-002", 1]]],
      ["isabella.rossi@example.com", "cancelled", 22, [["HDD-001", 1]]],
      ["james.wright@example.com",   "shipped",   16, [["MIC-001", 1], ["STAND-001", 1]]],
      ["james.wright@example.com",   "paid",       4, [["HEAD-002", 1]]],
      ["bob.martinez@example.com",   "shipped",   55, [["SSD-002", 1], ["HUB-001", 1]]]
    ]

    orders = order_specs.map do |email, status, days_ago, lines|
      order = Order.new(customer: Customer.find_by_email!(email), status: status)
      lines.each { |sku, qty| order.order_items.build(product: products_by_sku.fetch(sku), quantity: qty) }
      order.save!

      placed_at = days_ago.days.ago
      order.update_columns(created_at: placed_at, updated_at: placed_at)
      order
    end

    puts "Seeded #{orders.size} orders"

    # Payments: every paid/shipped order (and the refunded one) settled in full,
    # in a mix of currencies and methods. Pending and cancelled orders carry no
    # payment — except Alice's keyboard order below, which is paid off in two
    # installments (and flips from pending to paid via the payment callback).
    payment_reference = 1000
    settle = lambda do |order, currency_code, payment_method|
      rate = Currency.find_by_code(currency_code).usd_rate.to_f
      order.payments.create!(
        amount_cents: (order.total_cents / rate).ceil,
        currency_code: currency_code,
        payment_method: payment_method,
        reference: "PAY-#{payment_reference += 1}",
        paid_at: order.created_at + 1.day
      )
    end

    # [order index (1-based, into order_specs), currency, method]
    settlements = [
      [1,  "USD", "credit_card"],
      [2,  "EUR", "credit_card"],
      [5,  "INR", "netbanking"],
      [6,  "GBP", "credit_card"],
      [7,  "USD", "credit_card"],
      [8,  "USD", "netbanking"],
      [11, "EUR", "credit_card"],
      [12, "JPY", "credit_card"],
      [13, "USD", "credit_card"],
      [14, "SGD", "netbanking"],
      [15, "USD", "credit_card"],
      [16, "INR", "netbanking"],
      [18, "EUR", "credit_card"],
      [20, "CAD", "credit_card"],
      [21, "USD", "netbanking"],
      [22, "GBP", "credit_card"]
    ]

    settlements.each { |index, code, method| settle.call(orders[index - 1], code, method) }

    installment_order = orders[2]
    installment_order.payments.create!(
      amount_cents: (installment_order.total_cents * 0.6 / Currency.find_by_code("INR").usd_rate.to_f).ceil,
      currency_code: "INR",
      payment_method: "netbanking",
      reference: "PAY-#{payment_reference += 1}",
      notes: "First installment (60%)",
      paid_at: installment_order.created_at + 1.hour
    )

    remaining_usd_cents = installment_order.total_cents - installment_order.payments.sum(:amount_usd_cents)
    installment_order.payments.create!(
      amount_cents: (remaining_usd_cents / Currency.find_by_code("EUR").usd_rate.to_f).ceil + 1,
      currency_code: "EUR",
      payment_method: "credit_card",
      reference: "PAY-#{payment_reference += 1}",
      notes: "Final installment",
      paid_at: installment_order.created_at + 1.day
    )

    puts "Seeded #{Payment.count} payments (order ##{installment_order.id} paid in 2 installments, now #{installment_order.reload.status})"

    # Invoices for a handful of settled orders; the rest deliberately have
    # none. Carol's shipped order gets an invoice that is then voided.
    { 1 => 18, 8 => 8.5, 13 => 20, 14 => 18, 20 => 18 }.each do |index, tax_rate|
      Invoice.generate_for!(orders[index - 1], tax_rate: tax_rate)
    end

    voided = Invoice.generate_for!(orders[5], tax_rate: 18)
    voided.update!(status: "void")

    puts "Seeded #{Invoice.count} invoices (1 void)"
  else
    puts "Skipped order/payment/invoice seeding (#{Order.count} order(s) already present)"
  end
end
