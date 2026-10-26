require "test_helper"

class NotesTest < ActionDispatch::IntegrationTest
  setup do
    @password = "a secure password"
    @user = User.create!(username: "Writer", email: "writer@example.com", password: @password, password_confirmation: @password)
    @other = User.create!(username: "Other", email: "other@example.com", password: @password, password_confirmation: @password)
    @folder = @user.folders.create!(name: "School")
    @category = @user.categories.create!(name: "Study")
    @other_folder = @other.folders.create!(name: "Secret folder")
    @other_category = @other.categories.create!(name: "Secret category")
    @other_note = @other.notes.create!(title: "Secret note", content: "Do not show", folder: @other_folder, category: @other_category)
    post login_path, params: { email: @user.email, password: @password }
  end

  test "create read edit and delete a note through the pages" do
    get dashboard_path
    assert_select "a[href=?]", notes_path
    get notes_path
    assert_response :success
    assert_select "h2", "No notes found"
    get new_note_path
    assert_response :success
    assert_select "select[name='note[folder_id]'] option", text: @folder.name
    assert_select "option", text: @other_folder.name, count: 0
    assert_difference "@user.notes.count", 1 do
      post notes_path, params: { note: { title: "Lecture", content: "First line\nSecond line", folder_id: @folder.id, category_id: @category.id, user_id: @other.id } }
    end
    note = @user.notes.find_by!(title: "Lecture")
    assert_redirected_to note_path(note)
    follow_redirect!
    assert_select "h1", "Lecture"
    assert_includes response.body, "First line\nSecond line"
    assert_equal "no-store", response.headers["Cache-Control"]
    get edit_note_path(note)
    assert_response :success
    assert_select "textarea", "First line\nSecond line"
    patch note_path(note), params: { note: { title: "Revised", content: "Updated", folder_id: "", category_id: "", user_id: @other.id } }
    assert_redirected_to note_path(note)
    assert_equal "Revised", note.reload.title
    assert_equal @user.id, note.user_id
    assert_nil note.folder_id
    assert_nil note.category_id
    assert_difference "Note.count", -1 do
      delete note_path(note)
    end
    assert_redirected_to notes_path
    assert_raises(ActiveRecord::RecordNotFound) { get note_path(note) }
  end

  test "invalid forms preserve submitted text and do not save changes" do
    assert_no_difference "Note.count" do
      post notes_path, params: { note: { title: " ", content: "Keep this draft" } }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]", /Title/
    assert_select "textarea", "Keep this draft"
    note = @user.notes.create!(title: "Original", content: "Saved")
    patch note_path(note), params: { note: { title: "", content: "Unsaved changes" } }
    assert_response :unprocessable_entity
    assert_select "textarea", "Unsaved changes"
    assert_equal "Original", note.reload.title
    assert_equal "Saved", note.content
  end

  test "other users cannot read edit or delete a note" do
    [[:get, note_path(@other_note)], [:get, edit_note_path(@other_note)],
     [:patch, note_path(@other_note)], [:delete, note_path(@other_note)]].each do |method, path|
      assert_raises(ActiveRecord::RecordNotFound) { public_send(method, path, params: { note: { title: "Stolen" } }) }
    end
    assert_equal "Secret note", @other_note.reload.title
  end

  test "forged organization assignments are rejected on creation and update" do
    [{ folder_id: @other_folder.id }, { category_id: @other_category.id }, { folder_id: -1 }].each do |assignment|
      assert_no_difference "Note.count" do
        post notes_path, params: { note: { title: "Invalid" }.merge(assignment) }
      end
      assert_response :unprocessable_entity
      assert_select "[role=alert]", /workspace/
    end
    note = @user.notes.create!(title: "Own")
    patch note_path(note), params: { note: { folder_id: @other_folder.id, title: "Changed" } }
    assert_response :unprocessable_entity
    assert_equal "Own", note.reload.title
    assert_nil note.folder_id
  end

  test "search filters combine query folder and category and never expose another owner's data" do
    found = @user.notes.create!(title: "BIOLOGY", content: "Read chapter", folder: @folder, category: @category)
    @user.notes.create!(title: "Unrelated", content: "No match", folder: @folder)
    @user.notes.create!(title: "Biology elsewhere")
    get search_path, params: { q: "biology", folder_id: @folder.id, category_id: @category.id }
    assert_response :success
    assert_select "h1", "Search notes"
    assert_select "article h2 a", count: 1, text: found.title
    assert_select "option[selected]", text: @folder.name
    get search_path, params: { q: "CHAPTER" }
    assert_select "article h2 a", count: 1, text: found.title
    get search_path, params: { q: "Secret" }
    assert_select "h2", "No notes found"
    assert_not_includes response.body, @other_note.title
    assert_not_includes response.body, @other_folder.name
    assert_not_includes response.body, @other_category.name
    get search_path, params: { q: "   " }
    assert_select "article", count: 3
    get notes_path, params: { folder_id: @folder.id }
    assert_select "article", count: 2
    assert_raises(ActiveRecord::RecordNotFound) { get search_path, params: { folder_id: @other_folder.id } }
    assert_raises(ActiveRecord::RecordNotFound) { get notes_path, params: { category_id: @other_category.id } }
  end

  test "pagination keeps search filters" do
    21.times { |i| @user.notes.create!(title: "Lecture #{i}", folder: @folder, category: @category) }
    get search_path, params: { q: "Lecture", folder_id: @folder.id, category_id: @category.id }
    assert_select "article", count: 20
    next_url = css_select("nav[aria-label='Notes pages'] a").find { |link| link.text == "Next" }["href"]
    get next_url
    assert_select "article", count: 1
    assert_select "input[name=q][value=Lecture]"
    assert_select "option[selected]", text: @folder.name
    assert_select "option[selected]", text: @category.name
    assert_select "nav[aria-label='Notes pages'] a", "Previous"
  end

  test "note text is displayed as text and cannot inject HTML" do
    note = @user.notes.create!(title: "<script>alert('title')</script>", content: "<script>alert('body')</script><img src=x onerror=alert(1)>")
    get note_path(note)
    assert_response :success
    assert_select "script", count: 0
    assert_select "img", count: 0
    assert_includes response.body, "&lt;script&gt;"
    get notes_path
    assert_select "script", count: 0
    assert_select "img", count: 0
  end

  test "all notes organization and search routes require authentication" do
    delete logout_path
    note = @user.notes.create!(title: "Private")
    [[:get, notes_path], [:get, new_note_path], [:post, notes_path], [:get, note_path(note)],
     [:get, edit_note_path(note)], [:patch, note_path(note)], [:delete, note_path(note)],
     [:get, search_path], [:get, folders_path], [:post, folders_path], [:get, edit_folder_path(@folder)],
     [:patch, folder_path(@folder)], [:delete, folder_path(@folder)], [:get, categories_path],
     [:post, categories_path], [:get, edit_category_path(@category)], [:patch, category_path(@category)],
     [:delete, category_path(@category)]].each do |method, path|
      public_send(method, path)
      assert_redirected_to login_path
    end
    assert Note.exists?(note.id)
    assert Folder.exists?(@folder.id)
    assert Category.exists?(@category.id)
  end
end
