require "test_helper"

class NoteTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(username: "Owner", email: "owner@example.com", password: "a secure password", password_confirmation: "a secure password")
    @other = User.create!(username: "Other", email: "other@example.com", password: "a secure password", password_confirmation: "a secure password")
  end

  test "note requires an owner and a nonblank title" do
    assert_not Note.new(title: "Missing owner").valid?
    assert_not @user.notes.new(title: "  ").valid?
    assert_not @user.notes.new(title: "x" * 201).valid?
    assert_not @user.notes.new(title: "Too long", content: "x" * 100_001).valid?
    note = @user.notes.create!(title: "  A title  ")
    assert_equal "A title", note.title
    assert_equal "", note.content
    note.update!(content: nil)
    assert_equal "", note.reload.content
  end

  test "note accepts only its owner's folders and categories" do
    folder = @user.folders.create!(name: "School")
    category = @user.categories.create!(name: "Research")
    note = @user.notes.new(title: "Lecture", folder: folder, category: category)
    assert note.valid?
    note.folder = @other.folders.create!(name: "Private")
    assert_not note.valid?
    assert_includes note.errors[:folder], "must belong to your workspace"
    note.folder = folder
    note.category = @other.categories.create!(name: "Private")
    assert_not note.valid?
    assert_includes note.errors[:category], "must belong to your workspace"
    note.category = category
    note.folder_id = -1
    assert_not note.valid?
  end

  test "search matches title and content case insensitively and treats wildcard characters literally" do
    first = @user.notes.create!(title: "Biology", content: "Practice 100% and a_b, not a wildcard")
    second = @user.notes.create!(title: "Other", content: "Practice 1000 and axb")
    assert_equal [first.id], @user.notes.search("BIOLOGY").pluck(:id)
    assert_equal [first.id], @user.notes.search("WILDCARD").pluck(:id)
    assert_equal [first.id], @user.notes.search("100%").pluck(:id)
    assert_equal [first.id], @user.notes.search("a_b").pluck(:id)
    assert_empty @user.notes.search("' OR 1=1 --")
    assert_equal 2, @user.notes.search("   ").count
  end

  test "folders and categories require names unique within an owner and preserve notes when removed" do
    [Folder, Category].each do |model|
      group = model.create!(user: @user, name: "  School  ")
      assert_equal "School", group.name
      assert_not model.new(user: @user, name: "School").valid?
      assert_not model.new(user: @user, name: "  ").valid?
      assert_not model.new(user: @user, name: "x" * 81).valid?
      assert model.new(user: @other, name: "School").valid?
      note = @user.notes.create!(title: "Keep me", content: "My writing", model.model_name.param_key => group)
      group.destroy!
      note.reload
      assert_nil note.public_send("#{model.model_name.param_key}_id")
      assert_equal "My writing", note.content
    end
  end

  test "deleting an account cleans up its notes and organization without affecting another account" do
    folder = @user.folders.create!(name: "School")
    category = @user.categories.create!(name: "Study")
    @user.notes.create!(title: "Owned", folder: folder, category: category)
    other_note = @other.notes.create!(title: "Keep")
    @user.destroy!
    assert_not Note.exists?(user_id: @user.id)
    assert_not Folder.exists?(user_id: @user.id)
    assert_not Category.exists?(user_id: @user.id)
    assert Note.exists?(other_note.id)
  end
end
