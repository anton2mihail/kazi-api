module Api
  module V1
    module Admin
      class EmployersController < BaseController
        def suspend
          profile = EmployerProfile.find_by!(user_id: params[:id])
          profile.suspend!(notes: params[:notes])
          audit!("employer.suspend", profile, notes: params[:notes])
          render_success(EmployerProfileSerializer.render(profile))
        end

        def unsuspend
          profile = EmployerProfile.find_by!(user_id: params[:id])
          profile.unsuspend!
          audit!("employer.unsuspend", profile)
          render_success(EmployerProfileSerializer.render(profile))
        end
      end
    end
  end
end
