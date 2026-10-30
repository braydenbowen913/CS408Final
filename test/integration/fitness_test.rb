require "test_helper"

class FitnessTest < ActionDispatch::IntegrationTest
  setup do
    @password = "a secure password"
    @user = User.create!(username: "Lifter", email: "lifter@example.com", password: @password, password_confirmation: @password)
    @other = User.create!(username: "Other", email: "other@example.com", password: @password, password_confirmation: @password)
    @exercise = @user.exercises.create!(name: "Squat")
    @other_exercise = @other.exercises.create!(name: "Private exercise")
    @other_workout = @other.workouts.create!(attributes_for(@other_exercise))
    post login_path, params: { email: @user.email, password: @password }
  end

  test "record read edit and delete a workout with sets" do
    get dashboard_path
    assert_select "a[href=?]", workouts_path
    get new_workout_path
    assert_response :success
    assert_select "option", text: @exercise.name
    assert_select "option", text: @other_exercise.name, count: 0
    assert_difference ["Workout.count", "WorkoutExercise.count", "ExerciseSet.count"], 1 do
      post workouts_path, params: { workout: attributes_for(@exercise).merge(user_id: @other.id) }
    end
    workout = @user.workouts.last
    assert_redirected_to workout_path(workout)
    follow_redirect!
    assert_select "h1", "Leg day"
    assert_select "td", "42.50"
    assert_equal "no-store", response.headers["Cache-Control"]
    get edit_workout_path(workout)
    assert_response :success
    entry = workout.workout_exercises.first
    set = entry.exercise_sets.first
    patch workout_path(workout), params: { workout: { name: "Revised", workout_exercises_attributes: { "0" => { id: entry.id, exercise_id: @exercise.id, exercise_order: 1, exercise_sets_attributes: { "0" => { id: set.id, set_number: 1, repetitions: 10, weight: "45.25" } } } } } }
    assert_redirected_to workout_path(workout)
    assert_equal "Revised", workout.reload.name
    assert_equal 10, set.reload.repetitions
    assert_equal BigDecimal("45.25"), set.weight
    assert_difference ["Workout.count", "WorkoutExercise.count", "ExerciseSet.count"], -1 do
      delete workout_path(workout)
    end
    assert_redirected_to workouts_path
    assert Exercise.exists?(@exercise.id)
  end

  test "invalid nested data is atomic and preserves draft" do
    attributes = attributes_for(@exercise)
    attributes[:workout_exercises_attributes]["0"][:exercise_sets_attributes]["0"][:repetitions] = -1
    assert_no_difference ["Workout.count", "WorkoutExercise.count", "ExerciseSet.count"] do
      post workouts_path, params: { workout: attributes }
    end
    assert_response :unprocessable_entity
    assert_select "input[value='Leg day']"
    assert_select "[role=alert]", /Repetitions/
    post workouts_path, params: { workout: { name: "Empty", workout_date: Date.current } }
    assert_response :unprocessable_entity
  end

  test "add exercise and set buttons preserve unsaved form data" do
    assert_no_difference "Workout.count" do
      post workouts_path, params: { workout: attributes_for(@exercise), add_exercise: "1" }
    end
    assert_response :success
    assert_select "fieldset", count: 2
    assert_select "input[value='Leg day']"
    assert_no_difference "ExerciseSet.count" do
      post workouts_path, params: { workout: attributes_for(@exercise), add_set: "0" }
    end
    assert_response :success
    assert_select "input[name$='[repetitions]']", count: 2
    assert_select "input[value='42.5']"
  end

  test "history filters exercise sets and paginates without exposing other accounts" do
    other_own = @user.exercises.create!(name: "Press")
    workout = @user.workouts.create!(attributes_for(@exercise))
    @user.workouts.create!(attributes_for(other_own).merge(name: "Upper day"))
    get workouts_path, params: { exercise_id: @exercise.id }
    assert_response :success
    assert_select "article h2 a", text: workout.name, count: 1
    assert_not_includes response.body, "Upper day"
    assert_not_includes response.body, @other_exercise.name
    20.times { @user.workouts.create!(attributes_for(@exercise)) }
    get workouts_path, params: { exercise_id: @exercise.id }
    assert_select "article", count: 20
    next_url = css_select("nav[aria-label='Workout pages'] a").find { |link| link.text == "Next" }["href"]
    get next_url
    assert_select "article", count: 1
    assert_select "option[selected]", text: @exercise.name
    assert_raises(ActiveRecord::RecordNotFound) { get workouts_path, params: { exercise_id: @other_exercise.id } }
  end

  test "foreign workouts exercises and nested IDs cannot be accessed or assigned" do
    [[:get, workout_path(@other_workout)], [:get, edit_workout_path(@other_workout)],
     [:patch, workout_path(@other_workout)], [:delete, workout_path(@other_workout)],
     [:get, edit_exercise_path(@other_exercise)], [:patch, exercise_path(@other_exercise)],
     [:delete, exercise_path(@other_exercise)]].each do |method, path|
      assert_raises(ActiveRecord::RecordNotFound) { public_send(method, path) }
    end
    assert_no_difference "Workout.count" do
      post workouts_path, params: { workout: attributes_for(@other_exercise) }
    end
    assert_response :unprocessable_entity
    workout = @user.workouts.create!(attributes_for(@exercise))
    foreign_entry = @other_workout.workout_exercises.first
    assert_raises(ActiveRecord::RecordNotFound) do
      patch workout_path(workout), params: { workout: { workout_exercises_attributes: { "0" => { id: foreign_entry.id, _destroy: "1" } } } }
    end
    own_entry = workout.workout_exercises.first
    assert_raises(ActiveRecord::RecordNotFound) do
      patch workout_path(workout), params: { workout: { workout_exercises_attributes: { "0" => { id: own_entry.id, exercise_sets_attributes: { "0" => { id: foreign_entry.exercise_sets.first.id, _destroy: "1" } } } } } }
    end
    assert_equal 1, foreign_entry.exercise_sets.count
  end

  test "exercise management retains referenced exercises and escapes text" do
    post exercises_path, params: { exercise: { name: "<script>alert(1)</script>", muscle_group: "Legs", user_id: @other.id } }
    exercise = @user.exercises.find_by!(muscle_group: "Legs")
    get exercises_path
    assert_select "script", count: 0
    patch exercise_path(exercise), params: { exercise: { name: "Lunge" } }
    assert_equal "Lunge", exercise.reload.name
    @user.workouts.create!(attributes_for(exercise))
    assert_no_difference "Exercise.count" do
      delete exercise_path(exercise)
    end
    follow_redirect!
    assert_select "[role=alert]", /workout history/
    unused = @user.exercises.create!(name: "Unused")
    assert_difference "Exercise.count", -1 do
      delete exercise_path(unused)
    end
  end

  test "all fitness routes require login" do
    delete logout_path
    [[:get, workouts_path], [:get, new_workout_path], [:post, workouts_path],
     [:get, workout_path(@other_workout)], [:get, edit_workout_path(@other_workout)],
     [:patch, workout_path(@other_workout)], [:delete, workout_path(@other_workout)],
     [:get, exercises_path], [:post, exercises_path], [:get, edit_exercise_path(@exercise)],
     [:patch, exercise_path(@exercise)], [:delete, exercise_path(@exercise)]].each do |method, path|
      public_send(method, path)
      assert_redirected_to login_path
    end
  end

  test "multiple exercises and sets can be added and removed atomically" do
    press = @user.exercises.create!(name: "Press")
    attributes = attributes_for(@exercise)
    attributes[:workout_exercises_attributes]["1"] = {
      exercise_id: press.id, exercise_order: 2,
      exercise_sets_attributes: { "0" => { set_number: 1, repetitions: 5, weight: 0 },
                                 "1" => { set_number: 2, repetitions: 6, weight: "10.25" } }
    }
    assert_difference "ExerciseSet.count", 3 do
      post workouts_path, params: { workout: attributes }
    end
    workout = @user.workouts.last
    squat_entry, press_entry = workout.workout_exercises.to_a
    get workouts_path, params: { exercise_id: press.id }
    assert_select "article h3", text: "Press", count: 1
    assert_select "article h3", text: "Squat", count: 0
    assert_difference "ExerciseSet.count", -2 do
      patch workout_path(workout), params: { workout: { workout_exercises_attributes: {
        "0" => { id: squat_entry.id, _destroy: "1" },
        "1" => { id: press_entry.id, exercise_sets_attributes: { "0" => { id: press_entry.exercise_sets.first.id, _destroy: "1" } } }
      } } }
    end
    assert_redirected_to workout_path(workout)
    assert_equal 1, workout.reload.workout_exercises.count
    assert_equal 1, press_entry.exercise_sets.reload.count
    assert_no_difference "ExerciseSet.count" do
      patch workout_path(workout), params: { workout: { workout_exercises_attributes: { "0" => { id: press_entry.id, _destroy: "1" } } } }
    end
    assert_response :unprocessable_entity
    assert WorkoutExercise.exists?(press_entry.id)
  end

  private

  def attributes_for(exercise)
    { name: "Leg day", workout_date: "2026-10-30", notes: "Felt strong",
      workout_exercises_attributes: { "0" => { exercise_id: exercise.id, exercise_order: 1,
        exercise_sets_attributes: { "0" => { set_number: 1, repetitions: 8, weight: "42.5" } } } } }
  end
end
