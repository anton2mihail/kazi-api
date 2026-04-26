class NotificationPreferenceSerializer
  def self.render(preferences)
    {
      newJobs: preferences.new_jobs,
      applicationUpdates: preferences.application_updates,
      sms: preferences.sms,
      email: preferences.email
    }
  end
end
