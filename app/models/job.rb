class Job < ApplicationRecord
  belongs_to :employer, class_name: "User"
  has_many :job_applications, dependent: :destroy

  enum :status, {
    draft: "draft",
    active: "active",
    closed: "closed",
    expired: "expired"
  }

  validates :title, :trade, :location, :pay_min_cents, :status, presence: true
end
