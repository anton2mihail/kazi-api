class UserSerializer
  def self.render(user)
    {
      id: user.id,
      phone: user.phone,
      email: user.email,
      role: user.role,
      phone_verified: user.phone_verified,
      email_verified: user.email_verified,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
