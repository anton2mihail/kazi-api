module Api
  module V1
    module Admin
      class EmployerVerificationsController < BaseController
        def index
          profiles = EmployerProfile.includes(:user).order(verification_submitted_at: :asc, created_at: :asc)
          profiles = profiles.where(verification_status: params[:status]) if params[:status].present?

          render_success(profiles.map { |profile| EmployerProfileSerializer.render(profile) })
        end

        def approve
          profile = EmployerProfile.find(params[:id])
          profile.approve!(notes: params[:notes])
          audit!("employer_verification.approve", profile, notes: params[:notes])
          render_success(EmployerProfileSerializer.render(profile))
        end

        def reject
          profile = EmployerProfile.find(params[:id])
          profile.reject!(notes: params[:notes])
          audit!("employer_verification.reject", profile, notes: params[:notes])
          render_success(EmployerProfileSerializer.render(profile))
        end

        def request_more_info
          profile = EmployerProfile.find(params[:id])
          profile.request_more_info!(notes: params[:notes])
          audit!("employer_verification.request_more_info", profile, notes: params[:notes])
          render_success(EmployerProfileSerializer.render(profile))
        end
      end
    end
  end
end
