class ReportSerializer
  def self.render(report)
    {
      id: report.id,
      reporterId: report.reporter_id,
      jobId: report.job_id,
      targetType: report.target_type,
      targetId: report.target_id,
      reason: report.reason,
      details: report.details,
      status: report.status,
      adminNotes: report.admin_notes,
      reviewedAt: report.reviewed_at,
      reviewedBy: report.reviewed_by_id,
      createdAt: report.created_at,
      updatedAt: report.updated_at
    }
  end
end
