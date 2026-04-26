class InterviewRequestSerializer
  def self.render(request)
    worker_payload = JobApplicationSerializer.worker_payload(request.worker)
    employer_profile = request.employer.employer_profile

    {
      id: request.id,
      employerId: request.employer_id,
      employerName: employer_profile&.company_name,
      employerPhone: request.accepted? ? (employer_profile&.phone || request.employer.phone) : nil,
      employerEmail: request.accepted? ? (employer_profile&.email || request.employer.email) : nil,
      workerId: request.worker_id,
      workerName: worker_payload[:workerName],
      workerPhone: request.accepted? ? request.worker.phone : nil,
      workerEmail: request.accepted? ? request.worker.email : nil,
      jobId: request.job_id,
      jobTitle: request.job&.title,
      message: request.message,
      status: request.status,
      createdAt: request.created_at,
      respondedAt: request.responded_at
    }
  end
end
