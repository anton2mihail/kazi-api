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

  normalizes :phone, with: ->(phone) { phone.to_s.gsub(/\D/, "") }
  normalizes :email, with: ->(email) { email.to_s.strip.downcase.presence }

  validates :role, presence: true
  validates :phone, presence: true, uniqueness: true
end
