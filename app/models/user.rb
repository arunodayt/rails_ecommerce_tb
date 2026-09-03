class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy

  enum :role, { member: "member", manager: "manager", admin: "admin" }, default: "member", validate: true

  validates :username,
            presence: true,
            length: { minimum: 3, maximum: 50 },
            format: { with: /\A[a-zA-Z0-9_.-]+\z/, message: "only allows letters, numbers, and . _ -" },
            uniqueness: { case_sensitive: false }

  validates :password, length: { minimum: 8 }, allow_nil: true

  normalizes :username, with: ->(value) { value.strip }

  def self.find_by_username(username)
    return nil if username.blank?

    where("lower(username) = ?", username.to_s.strip.downcase).first
  end
end
