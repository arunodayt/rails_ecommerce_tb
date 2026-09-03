# Customer data - cannot log in.
class Customer < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error
  has_many :addresses, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }

  validates :email,
            presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { case_sensitive: false }

  normalizes :email, with: ->(value) { value.strip.downcase }

  def default_billing_address
    addresses.billing.order(default: :desc, id: :asc).first
  end

  # Case-insensitive lookup, mirroring User.find_by_username.
  def self.find_by_email(email)
    return nil if email.blank?

    where("lower(email) = ?", email.to_s.strip.downcase).first
  end
end
