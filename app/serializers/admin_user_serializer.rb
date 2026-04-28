class AdminUserSerializer
  def self.render(user)
    employer = user.employer_profile
    worker   = user.worker_profile

    {
      id: user.id,
      name: derive_name(user, worker: worker, employer: employer),
      email: user.email,
      phone: user.phone,
      role: user.role,
      suspended: user.suspended?,
      suspended_at: user.suspended_at,
      suspension_reason: user.suspension_reason,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end

  def self.derive_name(user, worker:, employer:)
    if worker
      full = [ worker.first_name, worker.last_name ].compact_blank.join(" ")
      return full if full.present?
    end

    return employer.contact_name if employer&.contact_name.present?
    return employer.company_name if employer&.company_name.present?

    user.email.presence || user.phone
  end
end
