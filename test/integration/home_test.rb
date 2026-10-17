require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "landing page provides account navigation and shared layout" do
    get "/"
    assert_response :success
    assert_select "h1", "Your life, with room to think."
    assert_select "nav a[href=?]", signup_path
    assert_select "nav a[href=?]", login_path
    assert_select "link[href*='bootstrap']"
    assert_select "footer", /Nexus/
  end

  test "health endpoint returns JSON success" do
    get "/api/health"
    assert_response :success
    assert_equal "ok", response.parsed_body["status"]
  end
end
