# Checkpoint 3 — Fitness Tracking

Scope: the five Checkpoint 3 deliverables in [CS408 Project Specification.pdf](CS408%20Project%20Specification.pdf).

| Requirement | Implementation and evidence |
| --- | --- |
| Exercise and workout models with relationships | [Migration](../db/migrate/20261030000000_create_fitness_tracking.rb), [Exercise](../app/models/exercise.rb), [Workout](../app/models/workout.rb), [WorkoutExercise](../app/models/workout_exercise.rb), and [ExerciseSet](../app/models/exercise_set.rb). Users own exercises/workouts; workouts contain ordered exercise entries, each containing numbered sets. Foreign keys protect relationships. |
| Create workout form with edit/delete | [Workout controller](../app/controllers/workouts_controller.rb), [shared form](../app/views/workouts/_form.html.erb), and [workout detail page](../app/views/workouts/show.html.erb). Create, edit, and delete workouts; add/remove exercises and sets. Nested changes save atomically and invalid drafts render with errors. |
| Record sets, reps, and weight | Numbered sets accept positive whole-number reps and nonnegative weights in kg with at most two decimal places. Zero supports bodyweight exercises. [Set model](../app/models/exercise_set.rb) validates input; database checks reject negative values. |
| Workout history page | [History page](../app/views/workouts/index.html.erb) lists workouts newest date first, with exercise names and set details, 20 workouts per page. Links open workout details and editing. |
| Exercise-specific history filtering | The history selector and exercise-library history links restrict results to workouts containing the selected exercise and display only that exercise's sets. Pagination retains the selected exercise. |

Additional supporting functionality: [exercise management](../app/controllers/exercises_controller.rb) supports create/edit/delete, muscle groups, and descriptions. Exercises used by a workout cannot be deleted until removed from its history. Fitness links appear in the shared header and dashboard. All routes require login; lookups use the current user's associations. Nested IDs from another workout and other users' exercise assignments are rejected. Fitness text is escaped by Rails and filtered from parameter logs.

## Validation

Verified locally in Ubuntu WSL with Ruby 3.3.8 and PostgreSQL 18:

- Full Rails suite: **38 tests, 403 assertions, 0 failures, 0 errors, 0 skips**.
- Checkpoint 2 to 3 migration: successfully applied to a test database containing an existing account and note; both remained intact. Migration reversal/reapplication also succeeded in that test database.
- `bundle exec rails zeitwerk:check`: passed.
- Bash syntax: all three repository scripts and the six Bash command blocks in the EC2 guide passed `bash -n`. The PowerShell upload block passed PowerShell parser validation.
- `git diff --check`: passed.

GitHub Actions remains configured for Ubuntu 24.04, Ruby 3.3, and PostgreSQL 16; that remote job was not run in this session. Browser interaction and live EC2 deployment were not verified here. Follow the update guide's browser checklist after deployment.

[Model tests](../test/models/workout_test.rb) cover persistence, relationships, validation, dependent deletion, and account deletion. [Integration tests](../test/integration/fitness_test.rb) cover workout/exercise workflows, retained invalid drafts, adding form rows without saving, history/filter pagination, HTML escaping, authentication, owner isolation, and forged nested IDs.

The EC2 update procedure is documented separately in [checkpoint-3-ec2-update.md](checkpoint-3-ec2-update.md), including backup, Windows PowerShell and Ubuntu/WSL commands, production migration, restart, smoke tests, and recovery. The existing deployment helper automatically applies the additive migration. No live deployment, Git tag, or push is performed as part of this implementation.

Charts and fitness dashboard summary widgets belong to Checkpoint 5. This checkpoint provides the persisted fitness data and history they will use.
