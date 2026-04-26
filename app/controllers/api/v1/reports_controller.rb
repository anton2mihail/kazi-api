module Api
  module V1
    class ReportsController < ApplicationController
      before_action :authenticate_user!, except: [ :create_job ]

      def create_job
        return unless optionally_authenticate_user!

        report = Report.new(
          reporter: current_user,
          job_id: params[:jobId] || params[:job_id],
          target_type: "Job",
          target_id: params[:jobId] || params[:job_id],
          reason: params[:reason],
          details: params[:details],
          status: "pending"
        )

        if report.save
          render_success(ReportSerializer.render(report), status: :created)
        else
          render_error("report_invalid", report.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def create_user
        report = Report.new(
          reporter: current_user,
          target_type: params[:targetType] || "User",
          target_id: params[:targetId] || params[:target_id],
          reason: params[:reason],
          details: params[:details],
          status: "pending"
        )

        if report.save
          render_success(ReportSerializer.render(report), status: :created)
        else
          render_error("report_invalid", report.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      private

      def optionally_authenticate_user!
        return true if request.authorization.blank?

        token = bearer_token
        session = UserSession.active.find_by(token_digest: UserSession.digest(token))
        return render_error("invalid_token", "Invalid or expired session.", status: :unauthorized) unless session

        session.update!(last_used_at: Time.current)
        @current_session = session
        @current_user = session.user
        true
      end
    end
  end
end
