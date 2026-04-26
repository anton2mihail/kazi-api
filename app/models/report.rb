class Report < ApplicationRecord
  belongs_to :reporter, class_name: "User", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true
  belongs_to :job, optional: true

  enum :status, {
    pending: "pending",
    reviewed: "reviewed",
    dismissed: "dismissed",
    actioned: "actioned"
  }

  validates :reason, :status, presence: true
end
