class JobApplicationSerializer
  def self.render(application, include_job: false, include_worker: false)
    payload = {
      id: application.id,
      applicationId: application.id,
      jobId: application.job_id,
      workerId: application.worker_id,
      status: application.status,
      coverNote: application.cover_note,
      appliedAt: application.created_at,
      updatedAt: application.updated_at
    }

    payload[:job] = JobSerializer.render(application.job, include_description: false) if include_job
    payload.merge!(worker_payload(application.worker)) if include_worker
    payload
  end

  def self.worker_payload(worker)
    profile = worker.worker_profile
    {
      workerId: worker.id,
      workerName: [ profile&.first_name, profile&.last_name ].compact_blank.join(" "),
      trade: profile&.primary_trade,
      trades: [ profile&.primary_trade, *(profile&.secondary_trades || []) ].compact_blank,
      experience: profile&.years_experience,
      yearsExperience: profile&.years_experience,
      location: [ profile&.city, profile&.province ].compact_blank.join(", "),
      bio: profile&.bio,
      certifications: [ *(profile&.certifications || []), *(profile&.custom_certifications || []) ],
      verifiedCerts: profile&.verified_certifications || [],
      skills: profile&.skills || [],
      hourlyRate: profile&.hourly_rate_min_cents&./(100),
      hasTransportation: profile&.has_transportation || false,
      hasOwnTools: profile&.has_own_tools || false,
      drivingLicenses: profile&.driving_licenses || [],
      emailVerified: worker.email_verified
    }
  end
end
