module Api
  module V1
    class NotificationPreferencesController < ApplicationController
      before_action :authenticate_user!

      def show
        render_success(NotificationPreferenceSerializer.render(preferences))
      end

      def update
        preferences.update!(
          new_jobs: boolean_param(:newJobs, preferences.new_jobs),
          application_updates: boolean_param(:applicationUpdates, preferences.application_updates),
          sms: boolean_param(:sms, preferences.sms),
          email: boolean_param(:email, preferences.email)
        )
        render_success(NotificationPreferenceSerializer.render(preferences))
      end

      private

      def preferences
        @preferences ||= current_user.notification_preference || current_user.create_notification_preference!
      end

      def boolean_param(key, default)
        return default unless params.key?(key)

        ActiveModel::Type::Boolean.new.cast(params[key])
      end
    end
  end
end
