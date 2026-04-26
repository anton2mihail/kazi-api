class EmployerProfileSerializer
  def self.render(profile)
    return nil unless profile

    {
      id: profile.id,
      userId: profile.user_id,
      companyName: profile.company_name,
      contactName: profile.contact_name,
      companySize: profile.company_size,
      industryType: profile.industry_type,
      website: profile.website,
      description: profile.description,
      headquarters: profile.city,
      serviceAreas: profile.service_areas,
      benefits: profile.benefits,
      verified: profile.verified,
      verificationStep: profile.verified? ? 4 : 3,
      createdAt: profile.created_at,
      updatedAt: profile.updated_at
    }
  end
end
