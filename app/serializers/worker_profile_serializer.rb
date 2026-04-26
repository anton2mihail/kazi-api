class WorkerProfileSerializer
  def self.render(profile)
    return nil unless profile

    {
      id: profile.id,
      userId: profile.user_id,
      firstName: profile.first_name,
      lastName: profile.last_name,
      bio: profile.bio,
      trades: [ profile.primary_trade, *profile.secondary_trades ].compact_blank,
      yearsExperience: profile.years_experience,
      startMonth: profile.start_month,
      startYear: profile.start_year,
      location: profile.city,
      province: profile.province,
      workAreas: profile.work_areas,
      availability: profile.availability,
      certifications: profile.certifications,
      customCertifications: profile.custom_certifications,
      verifiedCerts: profile.verified_certifications,
      skills: profile.skills,
      skillsAddedAt: profile.skills_added_at,
      hourlyRateMin: profile.hourly_rate_min_cents&./(100),
      hourlyRate: profile.hourly_rate_min_cents&./(100),
      workRadius: profile.work_radius,
      hasTransportation: profile.has_transportation,
      hasOwnTools: profile.has_own_tools,
      drivingLicenses: profile.driving_licenses,
      gender: profile.gender,
      followedCompanies: profile.followed_company_ids,
      profileUpdatedAt: profile.profile_updated_at || profile.updated_at,
      phone: profile.user.phone,
      email: profile.user.email,
      emailVerified: profile.user.email_verified,
      createdAt: profile.created_at,
      updatedAt: profile.updated_at
    }
  end
end
