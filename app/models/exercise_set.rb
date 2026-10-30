class ExerciseSet < ApplicationRecord
  belongs_to :workout_exercise, inverse_of: :exercise_sets
  validates :set_number, numericality: { only_integer: true, greater_than: 0 }
  validates :repetitions, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100_000 }
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than: 100_000_000 }
  validate :weight_precision

  private

  def weight_precision
    value = weight_before_type_cast
    precise = value.is_a?(Numeric) ? value.round(2) == value : value.to_s.match?(/\A\d+(\.\d{1,2})?\z/)
    if value.present? && !precise
      errors.add(:weight, "must be a number with at most two decimal places")
    end
  end
end
