class Exercise < ApplicationRecord
  belongs_to :user
  has_many :workout_exercises, dependent: :restrict_with_error
  normalizes :name, with: ->(name) { name.strip }
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :user_id }
  validates :muscle_group, length: { maximum: 100 }
  validates :description, length: { maximum: 10_000 }
end
