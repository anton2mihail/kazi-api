class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :job, optional: true

  validates :notification_type, :title, presence: true

  scope :unread, -> { where(read_at: nil) }
end
