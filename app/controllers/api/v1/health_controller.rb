module Api
  module V1
    class HealthController < ApplicationController
      def show
        render_success(
          {
            service: "kazitu-api",
            version: "v1"
          }
        )
      end
    end
  end
end
