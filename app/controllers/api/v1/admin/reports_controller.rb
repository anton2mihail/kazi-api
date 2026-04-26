module Api
  module V1
    module Admin
      class ReportsController < BaseController
        def index
          reports = Report.order(created_at: :desc)
          reports = reports.where(status: params[:status]) if params[:status].present?
          render_success(reports.map { |report| ReportSerializer.render(report) })
        end

        def update
          report = Report.find(params[:id])
          report.update!(
            status: params[:status] || report.status,
            admin_notes: params[:adminNotes] || params[:admin_notes],
            reviewed_at: Time.current,
            reviewed_by: current_user
          )
          audit!("report.update", report, status: report.status)
          render_success(ReportSerializer.render(report))
        end
      end
    end
  end
end
