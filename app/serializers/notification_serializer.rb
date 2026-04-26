class NotificationSerializer
  def self.render(notification)
    {
      id: notification.id,
      type: notification.notification_type,
      title: notification.title,
      message: notification.message,
      time: notification.created_at,
      read: notification.read_at.present?,
      readAt: notification.read_at,
      jobId: notification.job_id,
      companyId: notification.company_id
    }
  end
end
