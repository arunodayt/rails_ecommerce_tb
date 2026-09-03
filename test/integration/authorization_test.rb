require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @admin       = users(:admin)
    @manager     = users(:manager)
    @manager_two = users(:manager_two)
    @member      = users(:member)
    @member_two  = users(:member_two)
  end

  # --- index -------------------------------------------------------------

  test "admins and managers can list users; members cannot" do
    get users_path, headers: bearer(access_token_for(@admin))
    assert_response :ok
    get users_path, headers: bearer(access_token_for(@manager))
    assert_response :ok
    get users_path, headers: bearer(access_token_for(@member))
    assert_response :forbidden
  end

  # --- show --------------------------------------------------------------

  test "members can view themselves but not others" do
    get user_path(@member), headers: bearer(access_token_for(@member))
    assert_response :ok
    get user_path(@admin), headers: bearer(access_token_for(@member))
    assert_response :forbidden
  end

  test "managers can view other users" do
    get user_path(@admin), headers: bearer(access_token_for(@manager))
    assert_response :ok
  end

  # --- create (admin only) ----------------------------------------------

  test "only admins can create users" do
    body = { user: { username: "fresh", password: "password123" } }

    post users_path, params: body, headers: bearer(access_token_for(@manager)), as: :json
    assert_response :forbidden
    post users_path, params: body, headers: bearer(access_token_for(@member)), as: :json
    assert_response :forbidden
    post users_path, params: body, headers: bearer(access_token_for(@admin)), as: :json
    assert_response :created
  end

  # --- update ------------------------------------------------------------

  test "managers can update members" do
    patch user_path(@member),
          params: { user: { username: "renamed" } },
          headers: bearer(access_token_for(@manager)), as: :json
    assert_response :ok
  end

  test "managers cannot update other managers or admins" do
    token = access_token_for(@manager)
    patch user_path(@manager_two), params: { user: { username: "x" } }, headers: bearer(token), as: :json
    assert_response :forbidden
    patch user_path(@admin), params: { user: { username: "x" } }, headers: bearer(token), as: :json
    assert_response :forbidden
  end

  test "members can update only themselves" do
    # Reuse one token: the update below changes the member's username, which
    # would break a second login-by-username. The session is keyed by id anyway.
    token = access_token_for(@member)

    patch user_path(@member),
          params: { user: { username: "myself" } },
          headers: bearer(token), as: :json
    assert_response :ok

    patch user_path(@member_two),
          params: { user: { username: "nope" } },
          headers: bearer(token), as: :json
    assert_response :forbidden
  end

  # --- privilege escalation guard ---------------------------------------

  test "a member cannot escalate their own role" do
    patch user_path(@member),
          params: { user: { role: "admin" } },
          headers: bearer(access_token_for(@member)), as: :json
    assert_response :ok # update itself is allowed...
    assert_equal "member", @member.reload.role # ...but role was filtered out
  end

  test "a manager cannot promote a member" do
    patch user_path(@member),
          params: { user: { role: "manager" } },
          headers: bearer(access_token_for(@manager)), as: :json
    assert_response :ok
    assert_equal "member", @member.reload.role
  end

  test "an admin can change a user's role" do
    patch user_path(@member),
          params: { user: { role: "manager" } },
          headers: bearer(access_token_for(@admin)), as: :json
    assert_response :ok
    assert_equal "manager", @member.reload.role
  end

  # --- destroy -----------------------------------------------------------

  test "admins can delete members but not themselves" do
    admin_token = access_token_for(@admin)
    delete user_path(@member), headers: bearer(admin_token)
    assert_response :no_content

    delete user_path(@admin), headers: bearer(admin_token)
    assert_response :forbidden
  end

  test "managers can delete members but not managers" do
    token = access_token_for(@manager)
    delete user_path(@member), headers: bearer(token)
    assert_response :no_content

    delete user_path(@manager_two), headers: bearer(token)
    assert_response :forbidden
  end

  test "members cannot delete users" do
    delete user_path(@member_two), headers: bearer(access_token_for(@member))
    assert_response :forbidden
  end
end
