class WorkoutExercise < ApplicationRecord
  belongs_to :workout, inverse_of: :workout_exercises
  belongs_to :exercise
  has_many :exercise_sets, -> { order(:set_number, :id) }, inverse_of: :workout_exercise, dependent: :destroy
  accepts_nested_attributes_for :exercise_sets, allow_destroy: true,
    reject_if: ->(attributes) { attributes["id"].blank? && attributes["repetitions"].blank? && attributes["weight"].blank? }
  validates :exercise_order, numericality: { only_integer: true, greater_than: 0 }
  validate :exercise_belongs_to_owner
  validate :contains_set

  private

  def exercise_belongs_to_owner
    errors.add(:exercise, "must belong to your workspace") if exercise && workout && exercise.user_id != workout.user_id
  end

  def contains_set
    errors.add(:base, "Each exercise needs at least one recorded set.") unless exercise_sets.any? { |set| !set.marked_for_destruction? }
  end
end
