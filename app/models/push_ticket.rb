class PushTicket < ApplicationRecord
  belongs_to :device_token

  validates :ticket_id, presence: true, uniqueness: true
  validates :sent_at, presence: true
end
