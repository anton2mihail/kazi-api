module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authenticate_user!

      def index
        render_success(current_user.notifications.order(created_at: :desc).map { |notification| NotificationSerializer.render(notification) })
      end

      def read
        notification = current_user.notifications.find(params[:id])
        notification.update!(read_at: Time.current)
        render_success(NotificationSerializer.render(notification))
      end

      def read_all
        current_user.notifications.unread.update_all(read_at: Time.current, updated_at: Time.current)
        render_success({ read: true })
      end
    end
  end
end
