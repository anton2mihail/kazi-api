class ApplicationController < ActionController::API
  include Pundit::Authorization

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  attr_reader :current_user, :current_session

  def authenticate_user!
    token = bearer_token
    return render_error("auth_required", "Authentication required.", status: :unauthorized) if token.blank?

    session = UserSession.active.find_by(token_digest: UserSession.digest(token))
    return render_error("invalid_token", "Invalid or expired session.", status: :unauthorized) unless session

    if session.user.suspended?
      session.revoke!
      return render_error("account_suspended", "This account is suspended.", status: :forbidden)
    end

    session.update!(last_used_at: Time.current)
    @current_session = session
    @current_user = session.user
  end

  def require_role!(*roles)
    return true if roles.map(&:to_s).include?(current_user&.role)

    render_error("wrong_role", "This account cannot perform that action.", status: :forbidden)
    false
  end

  def render_success(data = {}, status: :ok)
    render json: { ok: true, data: data }, status: status
  end

  def render_error(code, message, status: :bad_request)
    render json: {
      ok: false,
      error: {
        code: code,
        message: message,
        request_id: request.request_id
      }
    }, status: status
  end

  def render_not_found
    render_error("not_found", "Resource not found.", status: :not_found)
  end

  def render_forbidden
    render_error("forbidden", "You are not allowed to perform this action.", status: :forbidden)
  end

  def bearer_token
    header = request.authorization.to_s
    return nil unless header.start_with?("Bearer ")

    header.delete_prefix("Bearer ").strip
  end
end
