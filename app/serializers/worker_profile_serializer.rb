class WorkerProfileSerializer
  def self.render(profile)
    return nil unless profile

    {
      id: profile.id,
      userId: profile.user_id,
      firstName: profile.first_name,
      lastName: profile.last_name,
      bio: profile.bio,
      trades: [profile.primary_trade, *profile.secondary_trades].compact_blank,
      yearsExperience: profile.years_experience,
      location: profile.city,
      province: profile.province,
      workAreas: profile.work_areas,
      availability: profile.availability,
      certifications: profile.certifications,
      skills: profile.skills,
      hourlyRateMin: profile.hourly_rate_min_cents&./(100),
      createdAt: profile.created_at,
      updatedAt: profile.updated_at
    }
  end
end
