**Tag:** [CS408Final](https://github.com/braydenbowen913/CS408Final)

**Live:** [http://34.215.193.101/](http://34.215.193.101/) — existing deployment; Checkpoint 2 has not been deployed by this change.

**Spec:** [Project Specification](https://docs.google.com/document/d/1NwcgdEPAzklRRTceeDcoAJX1L780D7bu7fS2BQSoWXg/edit?tab=t.0)

**Diff:** 30 files changed, 715 insertions(+), 9 deletions(-) relative to HEAD (including new files).

The implementations below are present locally. Runtime verification is pending because Windows Application Control blocks Ruby's `strscan.so`, preventing Rails boot and test execution. No Checkpoint 2 Git tag has been created or pushed. Evidence uses repository-relative links so it can be reviewed locally and after these changes are pushed.

| Deliverable (Checkpoint 2 — Notes and Search) | Status | Evidence |
| --- | --- | --- |
| Notes database tables and create/edit note forms | Implemented | [Migration](../db/migrate/20261025000000_create_notes_and_organization.rb), [schema](../db/schema.rb), and [shared create/edit form](../app/views/notes/_form.html.erb). Notes support a title, plain-text content, and optional folder/category. |
| Note delete functionality | Implemented | [Notes controller](../app/controllers/notes_controller.rb) scopes deletion to the current user. The [note page](../app/views/notes/show.html.erb) provides an expandable permanent-delete action. [Workflow tests](../test/integration/notes_test.rb) cover deletion and unauthorized attempts. |
| Working note page/editor with notes restricted to their owner | Implemented | [Note view](../app/views/notes/show.html.erb), [editor](../app/views/notes/edit.html.erb), and [owner-scoped controller](../app/controllers/notes_controller.rb). [Tests](../test/integration/notes_test.rb) cover reading, editing, validation, HTML escaping, login requirements, and cross-account access. |
| Basic folders and categories with a search page | Implemented | [Folder](../app/models/folder.rb) and [category](../app/models/category.rb) models, [management controller](../app/controllers/note_groups_controller.rb), [search page](../app/views/notes/index.html.erb), and [search scope](../app/models/note.rb). Supports creating/renaming/deleting organization lists and case-insensitive title/content search combined with folder/category filters. [Organization tests](../test/integration/note_groups_test.rb) cover ownership and preserving notes when groups are deleted. |

Verification: all 30 Ruby files and 16 Rails ERB templates pass syntax checks; all three Bash scripts pass syntax checks; `git diff --check` passes. Sixteen new automated tests have been added (27 total); the suite and migration execution remain unverified due to the Windows policy block. Run `RAILS_ENV=test bundle exec rails db:create db:prepare` followed by `bundle exec rails test` and `bundle exec rails zeitwerk:check` in the supported Ubuntu environment or GitHub Actions before deployment.
