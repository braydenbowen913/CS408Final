require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  def account
    { username: "Brayden", email: "brayden@example.com", password: "a secure password", password_confirmation: "a secure password" }
  end

  test "dashboard requires login" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "registration signs in and logout removes dashboard access" do
    get signup_path
    assert_response :success
    assert_difference "User.count", 1 do
      post signup_path, params: { user: account.merge(id: 900, admin: true) }
    end
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select "h1", "Welcome, Brayden."
    assert_select "form[action=?]", logout_path
    assert_equal "no-store", response.headers["Cache-Control"]
    delete logout_path
    assert_redirected_to root_path
    get dashboard_path
    assert_redirected_to login_path
  end

  test "invalid registration renders errors without creating an account" do
    assert_no_difference "User.count" do
      post signup_path, params: { user: account.merge(password_confirmation: "wrong") }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]", /confirmation/
    get dashboard_path
    assert_redirected_to login_path
  end

  test "login rejects wrong credentials then accepts normalized email" do
    User.create!(account)
    get login_path
    assert_response :success
    post login_path, params: { email: account[:email], password: "incorrect" }
    assert_response :unprocessable_entity
    get dashboard_path
    assert_redirected_to login_path
    post login_path, params: { email: " BRAYDEN@EXAMPLE.COM ", password: account[:password] }
    assert_redirected_to dashboard_path
    get signup_path
    assert_redirected_to dashboard_path
  end

  test "each account sees its own dashboard" do
    first = User.create!(account)
    second = User.create!(account.merge(username: "Other", email: "other@example.com"))
    post login_path, params: { email: first.email, password: account[:password] }
    get dashboard_path
    assert_select "dd", text: first.email
    assert_select "dd", text: second.email, count: 0
    delete logout_path
    post login_path, params: { email: second.email, password: account[:password] }
    get dashboard_path
    assert_select "h1", "Welcome, Other."
    assert_select "dd", text: first.email, count: 0
  end

  test "forms reject requests without CSRF token when protection is enabled" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    assert_raises(ActionController::InvalidAuthenticityToken) do
      post login_path, params: { email: "someone@example.com", password: "incorrect" }
    end
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
