module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :authenticate_user!
        before_action -> { require_role!(:admin) }

        private

        def audit!(action, subject, metadata = {})
          AuditLog.create!(
            actor: current_user,
            action: action,
            subject_type: subject.class.name,
            subject_id: subject.id,
            metadata: metadata
          )
        end
      end
    end
  end
end
