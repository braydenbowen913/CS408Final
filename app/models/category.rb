class Category < ApplicationRecord
  belongs_to :user
  has_many :notes, dependent: :nullify
  normalizes :name, with: ->(name) { name.strip }
  validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: :user_id }
end
