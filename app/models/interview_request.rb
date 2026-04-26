class InterviewRequest < ApplicationRecord
  MONTHLY_BROWSE_LIMIT = 5

  belongs_to :employer, class_name: "User"
  belongs_to :worker, class_name: "User"
  belongs_to :job, optional: true

  enum :status, {
    pending: "pending",
    accepted: "accepted",
    declined: "declined",
    cancelled: "cancelled"
  }

  validates :status, presence: true
  validates :worker_id, uniqueness: { scope: [ :employer_id, :job_id ], conditions: -> { where(cancelled_at: nil) } }

  scope :active, -> { where(cancelled_at: nil) }
  scope :browse_requests, -> { where(job_id: nil) }
end
