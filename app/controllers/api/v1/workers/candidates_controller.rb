module Api
  module V1
    module Workers
      class CandidatesController < ApplicationController
        before_action :authenticate_user!
        before_action -> { require_role!(:employer) }

        def index
          profile = current_user.employer_profile
          return render_error("employer_not_verified", "Employer verification is required to browse candidates.", status: :forbidden) unless profile&.verified?

          candidates = User.worker.joins(:worker_profile).includes(:worker_profile)
          candidates = candidates.where(worker_profiles: { primary_trade: params[:trade] }) if params[:trade].present? && params[:trade] != "All Trades"
          candidates = candidates.where(worker_profiles: { city: params[:location] }) if params[:location].present? && params[:location] != "All Locations"

          render_success(candidates.map { |worker| JobApplicationSerializer.worker_payload(worker) })
        end
      end
    end
  end
end
