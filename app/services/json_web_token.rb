# Stateless JSON Web Token encode/decode helper.
#
# Two token types are issued:
#   access: short-lived, sent on every authenticated request
#   refresh: long-lived, exchanged at /auth/refresh for a new access token
class JsonWebToken
  class DecodeError < StandardError; end

  ALGORITHM = "HS256".freeze

  ACCESS_TTL  = 5.minutes
  REFRESH_TTL = 1.day

  class << self
    def encode_access(user_id, session_id)
      encode(sub: user_id, type: "access", ttl: ACCESS_TTL, claims: { sid: session_id })
    end

    def encode_refresh(user_id, session_id, jti)
      encode(sub: user_id, type: "refresh", ttl: REFRESH_TTL, claims: { sid: session_id, jti: jti })
    end

    def decode(token, expected_type: nil)
      payload, = JWT.decode(token, secret, true, algorithm: ALGORITHM)
      payload = payload.with_indifferent_access

      if expected_type && payload[:type] != expected_type
        raise DecodeError, "expected #{expected_type} token"
      end

      payload
    rescue JWT::DecodeError, JWT::ExpiredSignature => e
      raise DecodeError, e.message
    end

    private

    def encode(sub:, type:, ttl:, claims: {})
      now = Time.current
      payload = {
        sub:  sub,
        type: type,
        iat:  now.to_i,
        exp:  (now + ttl).to_i
      }.merge(claims)
      JWT.encode(payload, secret, ALGORITHM)
    end

    def secret
      Rails.application.secret_key_base
    end
  end
end
