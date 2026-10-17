class User < ApplicationRecord
  has_secure_password
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :username, with: ->(username) { username.strip }
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 254 }
  validates :username, presence: true, length: { maximum: 50 }
  validates :password, length: { minimum: 12, maximum: 72 }, allow_nil: true
  validates :password_confirmation, presence: true, if: -> { password.present? }
end
