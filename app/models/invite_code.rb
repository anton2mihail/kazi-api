class InviteCode < ApplicationRecord
  belongs_to :used_by, class_name: "User", optional: true

  normalizes :code, with: ->(code) { code.to_s.strip.upcase }
  normalizes :contact_email, with: ->(email) { email.to_s.strip.downcase.presence }

  validates :code, :company_name, presence: true
  validates :code, uniqueness: true

  scope :active, -> { where(used_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.generate_code
    SecureRandom.alphanumeric(6).upcase
  end
end
