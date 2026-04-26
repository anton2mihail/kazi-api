class WorkHistorySerializer
  def self.render(work_history)
    {
      id: work_history.id,
      jobId: work_history.job_id,
      jobTitle: work_history.job_title,
      workerId: work_history.worker_id,
      employerId: work_history.employer_id,
      employerName: work_history.employer_name,
      status: work_history.status,
      workerMarkedAt: work_history.worker_marked_at,
      employerRespondedAt: work_history.employer_responded_at,
      employerConfirmed: work_history.employer_confirmed,
      autoVerifyAt: work_history.auto_verify_at,
      employerNotes: work_history.employer_notes,
      disputeReason: work_history.dispute_reason,
      disputeDetails: work_history.dispute_details,
      workerRating: work_history.worker_rating,
      workerReview: work_history.worker_review,
      employerRating: work_history.employer_rating,
      employerReview: work_history.employer_review,
      createdAt: work_history.created_at,
      updatedAt: work_history.updated_at
    }
  end
end
