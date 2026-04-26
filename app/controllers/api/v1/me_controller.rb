module Api
  module V1
    class MeController < ApplicationController
      before_action :authenticate_user!

      def show
        render_success(UserSerializer.render(current_user))
      end
    end
  end
end
