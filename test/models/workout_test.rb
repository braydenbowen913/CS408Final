require "test_helper"

class WorkoutTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(username: "Athlete", email: "athlete@example.com", password: "a secure password", password_confirmation: "a secure password")
    @exercise = @user.exercises.create!(name: "Squat")
  end

  test "valid nested workout persists relationships and deletion cascades" do
    workout = build_workout
    workout.save!
    assert_equal @exercise, workout.workout_exercises.first.exercise
    assert_equal BigDecimal("42.5"), workout.workout_exercises.first.exercise_sets.first.weight
    assert_difference ["Workout.count", "WorkoutExercise.count", "ExerciseSet.count"], -1 do
      workout.destroy!
    end
    assert Exercise.exists?(@exercise.id)
  end

  test "invalid dates empty workouts and invalid set values are rejected" do
    workout = build_workout
    workout.workout_date = "invalid"
    assert_not workout.valid?
    workout = build_workout
    set = workout.workout_exercises.first.exercise_sets.first
    [0, -1, "1.5", nil].each do |value|
      set.repetitions = value
      assert_not workout.valid?
    end
    set.repetitions = 8
    [-1, "abc", "1.234", nil].each do |value|
      set.weight = value
      assert_not workout.valid?
    end
    set.weight = 0
    assert workout.valid?
    workout.workout_exercises.first.exercise_sets.first.mark_for_destruction
    assert_not workout.valid?
    assert_not @user.workouts.new(name: "Empty", workout_date: Date.current).valid?
  end

  test "account deletion removes workout hierarchy before exercises" do
    build_workout.save!
    assert_difference ["Workout.count", "WorkoutExercise.count", "ExerciseSet.count", "Exercise.count"], -1 do
      @user.destroy!
    end
  end

  private

  def build_workout
    workout = @user.workouts.new(name: "Legs", workout_date: Date.current)
    entry = workout.workout_exercises.build(exercise: @exercise, exercise_order: 1)
    entry.exercise_sets.build(set_number: 1, repetitions: 8, weight: "42.5")
    workout
  end
end
