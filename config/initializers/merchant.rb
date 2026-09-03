# Mocked merchant identity printed on invoices; replace with real settings later.
Rails.application.config.x.merchant = {
  name: "Acme Inc.",
  address: {
    line1: "100 Market Street",
    city: "San Francisco",
    state: "CA",
    postal_code: "94105",
    country: "US"
  }
}
