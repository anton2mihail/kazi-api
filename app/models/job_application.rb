class JobApplication < ApplicationRecord
  belongs_to :job
  belongs_to :worker, class_name: "User"

  enum :status, {
    pending: "pending",
    reviewing: "reviewing",
    shortlisted: "shortlisted",
    interview_requested: "interview_requested",
    hired: "hired",
    rejected: "rejected",
    withdrawn: "withdrawn"
  }

  validates :status, presence: true
  validates :job_id, uniqueness: { scope: :worker_id }
end
