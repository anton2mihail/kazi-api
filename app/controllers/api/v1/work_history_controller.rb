module Api
  module V1
    class WorkHistoryController < ApplicationController
      before_action :authenticate_user!

      def index
        histories = if current_user.worker?
          current_user.worker_work_histories
        elsif current_user.employer?
          current_user.employer_work_histories
        else
          return render_error("wrong_role", "Unsupported account type.", status: :forbidden)
        end

        render_success(histories.order(created_at: :desc).map { |history| WorkHistorySerializer.render(history) })
      end

      def create
        return unless require_role!(:worker)

        job = Job.find(params[:jobId] || params[:job_id])
        history = current_user.worker_work_histories.build(
          job: job,
          employer: job.employer,
          job_title: job.title,
          employer_name: job.employer.employer_profile&.company_name,
          status: "pending_employer",
          worker_marked_at: Time.current,
          auto_verify_at: WorkHistory::AUTO_VERIFY_DAYS.days.from_now
        )

        if history.save
          render_success(WorkHistorySerializer.render(history), status: :created)
        else
          render_error("work_history_invalid", history.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def confirm
        return unless require_role!(:employer)

        history = current_user.employer_work_histories.find(params[:id])
        confirmed = ActiveModel::Type::Boolean.new.cast(params[:confirmed])
        history.update!(
          status: confirmed ? "verified" : "disputed",
          employer_responded_at: Time.current,
          employer_confirmed: confirmed,
          employer_notes: params[:notes]
        )
        render_success(WorkHistorySerializer.render(history))
      end

      def dispute
        history = WorkHistory.find(params[:id])
        unless history.worker_id == current_user.id || history.employer_id == current_user.id
          return render_error("forbidden", "You can only dispute your own work history.", status: :forbidden)
        end

        history.update!(
          status: "disputed",
          dispute_reason: params[:reason],
          dispute_details: params[:details]
        )
        render_success(WorkHistorySerializer.render(history))
      end

      def review
        history = WorkHistory.find(params[:id])
        unless history.worker_id == current_user.id || history.employer_id == current_user.id
          return render_error("forbidden", "You can only review your own completed work.", status: :forbidden)
        end

        if current_user.employer?
          history.assign_attributes(employer_rating: params[:rating], employer_review: params[:review])
        else
          history.assign_attributes(worker_rating: params[:rating], worker_review: params[:review])
        end

        if history.save
          render_success(WorkHistorySerializer.render(history))
        else
          render_error("review_invalid", history.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end
    end
  end
end
