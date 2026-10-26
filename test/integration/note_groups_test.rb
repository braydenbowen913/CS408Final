require "test_helper"

class NoteGroupsTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(username: "Writer", email: "writer@example.com", password: "a secure password", password_confirmation: "a secure password")
    @other = User.create!(username: "Other", email: "other@example.com", password: "a secure password", password_confirmation: "a secure password")
    post login_path, params: { email: @user.email, password: "a secure password" }
  end

  test "create rename filter and delete folders and categories while preserving notes" do
    [Folder, Category].each do |model|
      key = model.model_name.param_key
      collection = polymorphic_path(model)
      get collection
      assert_response :success
      assert_difference "model.count", 1 do
        post collection, params: { key => { name: "School", user_id: @other.id } }
      end
      assert_redirected_to collection
      group = model.find_by!(user: @user, name: "School")
      note = @user.notes.create!(title: "Keep", key => group)
      get collection
      assert_select "h2 a", "School"
      get edit_polymorphic_path(group)
      assert_response :success
      patch polymorphic_path(group), params: { key => { name: "Renamed" } }
      assert_redirected_to collection
      assert_equal "Renamed", group.reload.name
      get notes_path, params: { "#{key}_id" => group.id }
      assert_select "article h2 a", "Keep"
      delete polymorphic_path(group)
      assert_redirected_to collection
      assert_not model.exists?(group.id)
      assert_nil note.reload.public_send("#{key}_id")
    end
  end

  test "invalid names render errors on create and edit" do
    [Folder, Category].each do |model|
      key = model.model_name.param_key
      collection = polymorphic_path(model)
      post collection, params: { key => { name: " " } }
      assert_response :unprocessable_entity
      assert_select "[role=alert]", /Name/
      group = model.create!(user: @user, name: "Existing")
      post collection, params: { key => { name: "Existing" } }
      assert_response :unprocessable_entity
      patch polymorphic_path(group), params: { key => { name: "" } }
      assert_response :unprocessable_entity
      assert_equal "Existing", group.reload.name
    end
  end

  test "another user's groups cannot be listed edited or deleted" do
    [Folder, Category].each do |model|
      group = model.create!(user: @other, name: "Secret group")
      get polymorphic_path(model)
      assert_not_includes response.body, group.name
      assert_raises(ActiveRecord::RecordNotFound) { get edit_polymorphic_path(group) }
      assert_raises(ActiveRecord::RecordNotFound) { patch polymorphic_path(group), params: { model.model_name.param_key => { name: "Stolen" } } }
      assert_raises(ActiveRecord::RecordNotFound) { delete polymorphic_path(group) }
      assert_equal "Secret group", group.reload.name
    end
  end
end
