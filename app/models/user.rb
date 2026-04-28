class User < ApplicationRecord
  enum :role, {
    worker: "worker",
    employer: "employer",
    admin: "admin"
  }

  has_one :worker_profile, dependent: :destroy
  has_one :employer_profile, dependent: :destroy
  has_many :job_applications, foreign_key: :worker_id, dependent: :destroy
  has_many :jobs, foreign_key: :employer_id, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_many :otp_challenges, dependent: :destroy
  has_many :worker_interview_requests, class_name: "InterviewRequest", foreign_key: :worker_id, dependent: :destroy
  has_many :employer_interview_requests, class_name: "InterviewRequest", foreign_key: :employer_id, dependent: :destroy
  has_many :worker_work_histories, class_name: "WorkHistory", foreign_key: :worker_id, dependent: :destroy
  has_many :employer_work_histories, class_name: "WorkHistory", foreign_key: :employer_id, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_one :notification_preference, dependent: :destroy
  has_many :device_tokens, dependent: :destroy

  belongs_to :suspended_by, class_name: "User", optional: true

  scope :suspended, -> { where.not(suspended_at: nil) }
  scope :not_suspended, -> { where(suspended_at: nil) }

  normalizes :phone, with: ->(phone) { phone.to_s.gsub(/\D/, "") }
  normalizes :email, with: ->(email) { email.to_s.strip.downcase.presence }

  validates :role, presence: true
  validates :phone, presence: true, uniqueness: true

  def suspended?
    suspended_at.present?
  end

  def suspend!(reason: nil, by: nil, at: Time.current)
    update!(
      suspended_at: at,
      suspension_reason: reason.presence,
      suspended_by: by
    )
  end

  def unsuspend!
    update!(suspended_at: nil, suspension_reason: nil, suspended_by: nil)
  end
end
