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
          if params[:trade].present? && params[:trade] != "All Trades"
            candidates = candidates.where(
              "worker_profiles.primary_trade = :trade OR :trade = ANY (worker_profiles.secondary_trades)",
              trade: params[:trade]
            )
          end
          candidates = candidates.where(worker_profiles: { city: params[:location] }) if params[:location].present? && params[:location] != "All Locations"

          revealed_worker_ids = current_user.employer_interview_requests.accepted.where(worker_id: candidates.map(&:id)).distinct.pluck(:worker_id)
          render_success(
            candidates.map do |worker|
              JobApplicationSerializer.worker_payload(
                worker,
                contact_revealed: revealed_worker_ids.include?(worker.id)
              )
            end
          )
        end
      end
    end
  end
end
