require "test_helper"

class UserTest < ActiveSupport::TestCase
  def attributes
    { username: "Brayden", email: "brayden@example.com", password: "a secure password", password_confirmation: "a secure password" }
  end

  test "normalizes email and stores a password digest" do
    user = User.create!(attributes.merge(email: " BRAYDEN@EXAMPLE.COM "))
    assert_equal "brayden@example.com", user.email
    assert user.authenticate("a secure password")
    assert_not_equal "a secure password", user.password_digest
    assert_not user.authenticate("wrong password")
  end

  test "rejects duplicate email regardless of case" do
    User.create!(attributes)
    assert_not User.new(attributes.merge(email: "BRAYDEN@example.com")).valid?
  end

  test "requires valid account details and matching strong password" do
    [{ username: "" }, { email: "invalid" }, { password: "short" },
     { password_confirmation: "different" }, { password_confirmation: "" }].each do |invalid|
      assert_not User.new(attributes.merge(invalid)).valid?, invalid.inspect
    end
  end
end
