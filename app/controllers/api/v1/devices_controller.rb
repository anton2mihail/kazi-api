module Api
  module V1
    class DevicesController < ApplicationController
      before_action :authenticate_user!

      def create
        token = params[:expo_push_token].to_s.strip
        platform = params[:platform].to_s.strip

        if token.blank? || platform.blank?
          return render_error(
            "validation_failed",
            "expo_push_token and platform are required.",
            status: :unprocessable_entity
          )
        end

        unless DeviceToken::PLATFORMS.include?(platform)
          return render_error(
            "validation_failed",
            "platform must be one of #{DeviceToken::PLATFORMS.join(", ")}.",
            status: :unprocessable_entity
          )
        end

        existing = DeviceToken.find_by(expo_push_token: token)

        if existing
          existing.update!(
            user: current_user,
            platform: platform,
            app_version: params[:app_version].presence,
            locale: params[:locale].presence,
            active: true,
            last_seen_at: Time.current
          )
          return render_success({ device: serialize(existing) }, status: :ok)
        end

        device = DeviceToken.create!(
          user: current_user,
          expo_push_token: token,
          platform: platform,
          app_version: params[:app_version].presence,
          locale: params[:locale].presence,
          active: true,
          last_seen_at: Time.current
        )

        render_success({ device: serialize(device) }, status: :created)
      rescue ActiveRecord::RecordInvalid => e
        render_error("validation_failed", e.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
      end

      def destroy
        device = DeviceToken.find_by(expo_push_token: params[:token], user_id: current_user.id)
        return render_not_found unless device

        device.update!(active: false)
        head :no_content
      end

      private

      def serialize(device)
        {
          id: device.id,
          expo_push_token: device.expo_push_token,
          platform: device.platform,
          app_version: device.app_version,
          locale: device.locale,
          active: device.active,
          last_seen_at: device.last_seen_at
        }
      end
    end
  end
end
