class EmployerProfileSerializer
  def self.render(profile)
    return nil unless profile

    {
      id: profile.id,
      userId: profile.user_id,
      companyName: profile.company_name,
      contactName: profile.contact_name,
      jobTitle: profile.job_title,
      email: profile.email || profile.user.email,
      phone: profile.phone || profile.user.phone,
      companySize: profile.company_size,
      industryType: profile.industry_type,
      website: profile.website,
      description: profile.description,
      headquarters: profile.city,
      officeLocations: profile.office_locations,
      serviceAreas: profile.service_areas,
      benefits: profile.benefits,
      socialMedia: profile.social_media || {},
      verified: profile.verified,
      verificationStatus: profile.verification_status,
      verificationStep: profile.verification_step || (profile.verified? ? 4 : 3),
      verificationSubmittedAt: profile.verification_submitted_at,
      submittedAt: profile.verification_submitted_at,
      verifiedAt: profile.verified_at,
      rejectedAt: profile.rejected_at,
      suspendedAt: profile.suspended_at,
      createdAt: profile.created_at,
      updatedAt: profile.updated_at
    }
  end
end
