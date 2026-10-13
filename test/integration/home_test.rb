require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "landing page displays Hello World" do
    get "/"
    assert_response :success
    assert_select "h1", "Hello World"
  end

  test "health endpoint returns JSON success" do
    get "/api/health"
    assert_response :success
    assert_equal "ok", response.parsed_body["status"]
  end
end
