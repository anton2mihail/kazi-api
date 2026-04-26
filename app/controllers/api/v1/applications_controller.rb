module Api
  module V1
    class ApplicationsController < ApplicationController
      before_action :authenticate_user!

      def index
        return worker_index if current_user.worker?
        return employer_index if current_user.employer?

        render_error("wrong_role", "Unsupported account type.", status: :forbidden)
      end

      def create
        return unless require_role!(:worker)

        job = Job.active.find(params[:job_id])
        application = job.job_applications.build(
          worker: current_user,
          cover_note: params[:coverNote],
          status: "pending"
        )

        if application.save
          render_success(JobApplicationSerializer.render(application, include_job: true), status: :created)
        else
          render_error("application_invalid", application.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def update
        application = JobApplication.find(params[:id])

        if current_user.worker?
          return render_error("forbidden", "You can only update your own applications.", status: :forbidden) unless application.worker_id == current_user.id
          return render_error("unsupported_status", "Workers can only withdraw applications.", status: :unprocessable_entity) unless params[:status] == "withdrawn"

          application.assign_attributes(status: "withdrawn", withdrawn_at: Time.current)
        elsif current_user.employer?
          return render_error("forbidden", "You can only manage applications for your jobs.", status: :forbidden) unless application.job.employer_id == current_user.id

          status = params[:status].to_s
          return render_error("unsupported_status", "Unsupported application status.", status: :unprocessable_entity) unless JobApplication.statuses.key?(status)

          application.status = status
        else
          return render_error("wrong_role", "Unsupported account type.", status: :forbidden)
        end

        if application.save
          render_success(JobApplicationSerializer.render(application))
        else
          render_error("application_invalid", application.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def for_job
        return unless require_role!(:employer)

        job = Job.find(params[:job_id])
        return render_error("forbidden", "You can only view applicants for your jobs.", status: :forbidden) unless job.employer_id == current_user.id

        applications = job.job_applications.includes(worker: :worker_profile).order(created_at: :desc)
        render_success(applications.map { |application| JobApplicationSerializer.render(application, include_worker: true) })
      end

      private

      def worker_index
        applications = current_user.job_applications.includes(job: { employer: :employer_profile }).order(created_at: :desc)
        render_success(applications.map { |application| JobApplicationSerializer.render(application, include_job: true) })
      end

      def employer_index
        applications = JobApplication.joins(:job).where(jobs: { employer_id: current_user.id }).includes(:job, worker: :worker_profile)
        render_success(applications.map { |application| JobApplicationSerializer.render(application, include_worker: true) })
      end
    end
  end
end
