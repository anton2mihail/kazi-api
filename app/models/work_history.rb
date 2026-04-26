class WorkHistory < ApplicationRecord
  AUTO_VERIFY_DAYS = 7

  belongs_to :job, optional: true
  belongs_to :worker, class_name: "User"
  belongs_to :employer, class_name: "User"

  enum :status, {
    pending_employer: "pending_employer",
    verified: "verified",
    verified_no_response: "verified_no_response",
    disputed: "disputed",
    resolved: "resolved"
  }

  validates :job_title, :status, presence: true
  validates :job_id, uniqueness: { scope: :worker_id, allow_nil: true }
  validates :worker_rating, :employer_rating, inclusion: { in: 1..5, allow_nil: true }
end
