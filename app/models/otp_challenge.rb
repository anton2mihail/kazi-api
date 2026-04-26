class OtpChallenge < ApplicationRecord
  CODE_LENGTH = 6
  TTL = 10.minutes
  MAX_ATTEMPTS = 5

  belongs_to :user, optional: true

  enum :purpose, {
    login: "login",
    signup: "signup"
  }

  normalizes :phone, with: ->(phone) { phone.to_s.gsub(/\D/, "") }

  validates :phone, :code_digest, :purpose, :expires_at, presence: true

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.current) }

  def self.generate_code
    SecureRandom.random_number(10**CODE_LENGTH).to_s.rjust(CODE_LENGTH, "0")
  end

  def self.digest(code)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, code.to_s)
  end

  def expired?
    expires_at <= Time.current
  end

  def verify(code)
    return false if consumed_at.present? || expired? || attempts_count >= MAX_ATTEMPTS

    increment!(:attempts_count)
    ActiveSupport::SecurityUtils.secure_compare(code_digest, self.class.digest(code.to_s))
  end
end
