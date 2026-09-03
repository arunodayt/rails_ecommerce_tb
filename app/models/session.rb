# A Session represents one login. Both the access and
# refresh tokens issued at login carry this record's id as their "sid" claim,
# so revoking the session (logout) instantly invalidates both tokens — every
# authenticated request checks that its session is still active.
class Session < ApplicationRecord
  belongs_to :user

  validates :refresh_jti, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where(expires_at: Time.current..) }

  # Opens a new session for the given user and returns it.
  def self.start!(user, user_agent: nil, ip_address: nil)
    create!(
      user:         user,
      refresh_jti:  SecureRandom.uuid,
      expires_at:   JsonWebToken::REFRESH_TTL.from_now,
      last_used_at: Time.current,
      user_agent:   user_agent,
      ip_address:   ip_address
    )
  end

  def active?
    revoked_at.nil? && expires_at.future?
  end

  # Issues a fresh access/refresh token pair bound to this session's current
  # refresh_jti. Does not rotate — call rotate_refresh! first when refreshing.
  def token_response
    {
      access_token:  JsonWebToken.encode_access(user_id, id),
      refresh_token: JsonWebToken.encode_refresh(user_id, id, refresh_jti),
      token_type:    "Bearer",
      expires_in:    JsonWebToken::ACCESS_TTL.to_i
    }
  end

  def rotate_refresh!
    update!(
      refresh_jti:  SecureRandom.uuid,
      expires_at:   JsonWebToken::REFRESH_TTL.from_now,
      last_used_at: Time.current
    )
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked_at
  end
end
