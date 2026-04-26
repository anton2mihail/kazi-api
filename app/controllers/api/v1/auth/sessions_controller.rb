module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        before_action :authenticate_user!

        def destroy
          current_session&.revoke!
          render_success({ logged_out: true })
        end
      end
    end
  end
end
