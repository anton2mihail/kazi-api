class DeviceToken < ApplicationRecord
  PLATFORMS = %w[ios android web].freeze

  belongs_to :user
  has_many :push_tickets, dependent: :destroy

  validates :expo_push_token, presence: true, uniqueness: true
  validates :platform, presence: true, inclusion: { in: PLATFORMS }

  scope :active, -> { where(active: true) }

  def mark_seen!
    update!(last_seen_at: Time.current)
  end

  def deactivate!
    update!(active: false)
  end
end
