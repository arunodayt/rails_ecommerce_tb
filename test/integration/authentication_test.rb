require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup { @admin = users(:admin) }

  # --- login -------------------------------------------------------------

  test "login with valid credentials returns a token pair" do
    post auth_login_path, params: { username: @admin.username, password: "password123" }, as: :json

    assert_response :ok
    assert response.parsed_body["access_token"].present?
    assert response.parsed_body["refresh_token"].present?
    assert_equal @admin.id, response.parsed_body.dig("user", "id")
  end

  test "login with a wrong password is rejected" do
    post auth_login_path, params: { username: @admin.username, password: "wrong" }, as: :json
    assert_response :unauthorized
  end

  test "login with an unknown user is rejected" do
    post auth_login_path, params: { username: "ghost", password: "password123" }, as: :json
    assert_response :unauthorized
  end

  # --- access gating -----------------------------------------------------

  test "me requires an access token" do
    get me_path
    assert_response :unauthorized
  end

  test "me succeeds with a valid access token" do
    get me_path, headers: bearer(access_token_for(@admin))
    assert_response :ok
    assert_equal @admin.username, response.parsed_body["username"]
  end

  test "a refresh token cannot be used as an access token" do
    refresh = login(@admin)["refresh_token"]
    get me_path, headers: bearer(refresh)
    assert_response :unauthorized
  end

  # --- instant logout ----------------------------------------------------

  test "logout immediately invalidates the still-unexpired access token" do
    access = access_token_for(@admin)
    get me_path, headers: bearer(access)
    assert_response :ok

    delete auth_logout_path, headers: bearer(access)
    assert_response :no_content

    # Same, not-yet-expired token must now be rejected.
    get me_path, headers: bearer(access)
    assert_response :unauthorized
  end

  test "logout_all revokes every active session for the user" do
    access_one = access_token_for(@admin)
    access_two = access_token_for(@admin)

    delete auth_logout_all_path, headers: bearer(access_one)
    assert_response :no_content

    get me_path, headers: bearer(access_one)
    assert_response :unauthorized
    get me_path, headers: bearer(access_two)
    assert_response :unauthorized
  end

  # --- refresh + rotation + reuse detection ------------------------------

  test "refresh returns a new working token pair" do
    refresh = login(@admin)["refresh_token"]

    post auth_refresh_path, params: { refresh_token: refresh }, as: :json
    assert_response :ok

    get me_path, headers: bearer(response.parsed_body["access_token"])
    assert_response :ok
  end

  test "replaying a rotated refresh token is rejected and kills the session" do
    original = login(@admin)["refresh_token"]

    # First refresh rotates the token.
    post auth_refresh_path, params: { refresh_token: original }, as: :json
    assert_response :ok
    rotated = response.parsed_body["refresh_token"]

    # Replaying the original (already-rotated) token is reuse → 401.
    post auth_refresh_path, params: { refresh_token: original }, as: :json
    assert_response :unauthorized

    # Reuse revoked the whole session, so even the rotated token is now dead.
    post auth_refresh_path, params: { refresh_token: rotated }, as: :json
    assert_response :unauthorized
  end
end
