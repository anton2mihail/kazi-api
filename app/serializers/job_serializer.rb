class JobSerializer
  def self.render(job, include_description: true, applicant_count: nil, applicants: nil)
    employer_profile = job.employer.employer_profile
    pay_min = cents_to_dollars(job.pay_min_cents)
    pay_max = cents_to_dollars(job.pay_max_cents)

    payload = {
      id: job.id,
      title: job.title,
      company: employer_profile&.company_name,
      companyId: job.employer_id,
      location: job.location,
      payMin: pay_min,
      payMax: pay_max,
      pay: pay_label(pay_min, pay_max),
      type: job.job_type,
      hoursPerWeek: job.hours_per_week,
      duration: job.duration,
      postedDate: job.published_at,
      expiresAt: job.expires_at,
      urgent: job.urgent,
      verified: employer_profile&.verified? || false,
      status: job.status,
      trades: [ job.trade ].compact_blank,
      benefits: job.benefits,
      requiredCerts: job.required_certifications,
      preferredCerts: job.preferred_certifications,
      requiredSkills: job.required_skills,
      preferredSkills: job.preferred_skills,
      applicantCount: applicant_count
    }

    payload[:description] = job.description if include_description
    payload[:applicants] = applicants if applicants
    payload
  end

  def self.list(jobs, applicant_counts: {})
    jobs.map do |job|
      render(job, include_description: true, applicant_count: applicant_counts[job.id] || 0)
    end
  end

  def self.cents_to_dollars(cents)
    return nil if cents.nil?

    cents / 100
  end

  def self.pay_label(pay_min, pay_max)
    return nil if pay_min.nil?
    return "$#{pay_min}/hr" if pay_max.blank? || pay_max == pay_min

    "$#{pay_min}-#{pay_max}/hr"
  end
end
