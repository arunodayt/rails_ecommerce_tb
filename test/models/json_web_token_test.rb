require "test_helper"

class JsonWebTokenTest < ActiveSupport::TestCase
  test "access token round-trips with its claims" do
    token = JsonWebToken.encode_access(42, 7)
    payload = JsonWebToken.decode(token, expected_type: "access")

    assert_equal 42, payload[:sub]
    assert_equal 7, payload[:sid]
    assert_equal "access", payload[:type]
  end

  test "refresh token carries a jti" do
    token = JsonWebToken.encode_refresh(42, 7, "the-jti")
    payload = JsonWebToken.decode(token, expected_type: "refresh")

    assert_equal "refresh", payload[:type]
    assert_equal "the-jti", payload[:jti]
  end

  test "decode rejects a token of the wrong type" do
    token = JsonWebToken.encode_access(1, 1)

    assert_raises(JsonWebToken::DecodeError) do
      JsonWebToken.decode(token, expected_type: "refresh")
    end
  end

  test "decode rejects a tampered token" do
    token = JsonWebToken.encode_access(1, 1)

    assert_raises(JsonWebToken::DecodeError) do
      JsonWebToken.decode("#{token}tampered")
    end
  end

  test "decode rejects an expired token" do
    token = JsonWebToken.encode_access(1, 1)

    travel JsonWebToken::ACCESS_TTL + 1.minute do
      assert_raises(JsonWebToken::DecodeError) { JsonWebToken.decode(token) }
    end
  end
end
