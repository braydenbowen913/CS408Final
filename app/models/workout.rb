class Workout < ApplicationRecord
  belongs_to :user
  has_many :workout_exercises, -> { order(:exercise_order, :id) }, inverse_of: :workout, dependent: :destroy
  accepts_nested_attributes_for :workout_exercises, allow_destroy: true
  validates :name, presence: true, length: { maximum: 150 }
  validates :workout_date, presence: true
  validates :notes, length: { maximum: 20_000 }
  validate :contains_exercise

  private

  def contains_exercise
    errors.add(:base, "Add at least one exercise with a recorded set.") unless workout_exercises.any? { |entry| !entry.marked_for_destruction? }
  end
end
