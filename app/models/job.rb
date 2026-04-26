class Job < ApplicationRecord
  belongs_to :employer, class_name: "User"
  has_many :job_applications, dependent: :destroy

  enum :status, {
    draft: "draft",
    active: "active",
    closed: "closed",
    expired: "expired"
  }

  scope :visible, -> { where(archived_at: nil) }
  scope :current, -> { visible.where(status: "active").where("expires_at IS NULL OR expires_at > ?", Time.current) }

  validates :title, :trade, :location, :pay_min_cents, :status, presence: true

  def repost!
    update!(
      status: "active",
      published_at: Time.current,
      expires_at: 30.days.from_now,
      closed_at: nil,
      archived_at: nil
    )
  end

  def archive!
    update!(archived_at: Time.current, status: "closed", closed_at: Time.current)
  end
end
