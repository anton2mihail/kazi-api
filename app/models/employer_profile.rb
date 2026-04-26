class EmployerProfile < ApplicationRecord
  belongs_to :user

  enum :verification_status, {
    pending: "pending",
    approved: "approved",
    rejected: "rejected",
    more_info_requested: "more_info_requested",
    suspended: "suspended"
  }, prefix: :verification

  validates :user_id, uniqueness: true

  def approve!(notes: nil)
    update!(
      verified: true,
      verification_status: "approved",
      verification_step: 4,
      verified_at: Time.current,
      rejected_at: nil,
      suspended_at: nil,
      verification_notes: notes.presence || verification_notes
    )
  end

  def reject!(notes: nil)
    update!(
      verified: false,
      verification_status: "rejected",
      verification_step: 3,
      rejected_at: Time.current,
      verification_notes: notes.presence || verification_notes
    )
  end

  def request_more_info!(notes: nil)
    update!(
      verified: false,
      verification_status: "more_info_requested",
      verification_step: 2,
      verification_notes: notes.presence || verification_notes
    )
  end

  def suspend!(notes: nil)
    update!(
      verified: false,
      verification_status: "suspended",
      suspended_at: Time.current,
      verification_notes: notes.presence || verification_notes
    )
  end

  def unsuspend!
    update!(
      verified: true,
      verification_status: "approved",
      verification_step: 4,
      suspended_at: nil
    )
  end
end
