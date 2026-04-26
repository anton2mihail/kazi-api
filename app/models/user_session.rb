class UserSession < ApplicationRecord
  TOKEN_BYTES = 32
  TTL = 30.days

  belongs_to :user

  validates :token_digest, :expires_at, presence: true
  validates :token_digest, uniqueness: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue_for!(user, user_agent: nil, ip_address: nil)
    token = SecureRandom.base64(TOKEN_BYTES)
    session = user.user_sessions.create!(
      token_digest: digest(token),
      user_agent: user_agent,
      ip_address: ip_address,
      expires_at: TTL.from_now,
      last_used_at: Time.current
    )

    [ token, session ]
  end

  def self.digest(token)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, token.to_s)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
