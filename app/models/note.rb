class Note < ApplicationRecord
  belongs_to :user
  belongs_to :folder, optional: true
  belongs_to :category, optional: true

  normalizes :title, with: ->(title) { title.strip }
  normalizes :content, with: ->(content) { content.to_s }, apply_to_nil: true
  validates :title, presence: true, length: { maximum: 200 }
  validates :content, length: { maximum: 100_000 }
  validate :organization_belongs_to_owner

  scope :recent_first, -> { order(updated_at: :desc, id: :desc) }
  scope :search, ->(query) {
    pattern = "%#{sanitize_sql_like(query.to_s.strip)}%"
    where("notes.title ILIKE :pattern OR notes.content ILIKE :pattern", pattern: pattern)
  }

  private

  def organization_belongs_to_owner
    [:folder, :category].each do |association|
      record = public_send(association)
      if public_send("#{association}_id").present? && (!record || record.user_id != user_id)
        errors.add(association, "must belong to your workspace")
      end
    end
  end
end
