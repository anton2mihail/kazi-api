module Api
  module V1
    class InterviewRequestsController < ApplicationController
      before_action :authenticate_user!

      def index
        requests = if current_user.worker?
          current_user.worker_interview_requests.includes(:job, employer: :employer_profile, worker: :worker_profile)
        elsif current_user.employer?
          current_user.employer_interview_requests.includes(:job, employer: :employer_profile, worker: :worker_profile)
        else
          return render_error("wrong_role", "Unsupported account type.", status: :forbidden)
        end

        render_success(requests.order(created_at: :desc).map { |request| InterviewRequestSerializer.render(request) })
      end

      def create
        return unless require_role!(:employer)
        return render_error("employer_not_verified", "Employer verification is required to request interviews.", status: :forbidden) unless current_user.employer_profile&.verified?

        job = Job.visible.find_by(id: params[:jobId] || params[:job_id])
        return render_error("monthly_limit_reached", "Monthly browse interview request limit reached.", status: :forbidden) if job.nil? && monthly_browse_limit_reached?

        request = current_user.employer_interview_requests.build(
          worker_id: params[:workerId] || params[:worker_id],
          job: job,
          message: params[:message],
          status: "pending"
        )

        if request.save
          render_success(InterviewRequestSerializer.render(request), status: :created)
        else
          render_error("interview_request_invalid", request.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def respond
        return unless require_role!(:worker)

        request = current_user.worker_interview_requests.active.find(params[:id])
        status = params[:status].to_s
        return render_error("unsupported_status", "Workers can only accept or decline interview requests.", status: :unprocessable_entity) unless %w[accepted declined].include?(status)

        request.update!(status: status, responded_at: Time.current)
        render_success(InterviewRequestSerializer.render(request))
      end

      def cancel
        request = InterviewRequest.active.find(params[:id])
        unless request.employer_id == current_user.id || request.worker_id == current_user.id
          return render_error("forbidden", "You can only cancel your own interview requests.", status: :forbidden)
        end

        request.update!(status: "cancelled", cancelled_at: Time.current)
        render_success(InterviewRequestSerializer.render(request))
      end

      private

      def monthly_browse_limit_reached?
        current_user.employer_interview_requests.browse_requests.where("created_at > ?", 30.days.ago).count >= InterviewRequest::MONTHLY_BROWSE_LIMIT
      end
    end
  end
end
