module Api
  module V1
    module Admin
      class UsersController < BaseController
        MAX_PER_PAGE = 100
        DEFAULT_PER_PAGE = 20

        def index
          page = [ params[:page].to_i, 1 ].max
          per_page = params[:per_page].to_i
          per_page = DEFAULT_PER_PAGE if per_page <= 0
          per_page = [ per_page, MAX_PER_PAGE ].min

          scope = User
                    .left_outer_joins(:worker_profile, :employer_profile)
                    .order(created_at: :desc)

          scope = apply_search(scope, params[:q])
          scope = apply_role(scope, params[:role])
          scope = apply_suspended(scope, params[:suspended])

          total = scope.count
          users = scope
                    .includes(:worker_profile, :employer_profile)
                    .offset((page - 1) * per_page)
                    .limit(per_page)
                    .to_a

          render_success({
            users: users.map { |user| AdminUserSerializer.render(user) },
            meta: {
              page: page,
              per_page: per_page,
              total: total,
              total_pages: (total.to_f / per_page).ceil
            }
          })
        end

        def suspend
          user = User.find(params[:id])

          return render_error("cannot_suspend_admin", "Admin users cannot be suspended.", status: :unprocessable_entity) if user.admin?
          return render_error("already_suspended", "User is already suspended.", status: :unprocessable_entity) if user.suspended?

          user.suspend!(reason: params[:reason], by: current_user)
          audit!("user.suspend", user, reason: params[:reason])

          render_success({ user: AdminUserSerializer.render(user.reload) })
        end

        def test_push
          user = User.find(params[:id])

          if user.device_tokens.active.none?
            return render_error("no_active_devices", "User has no active device tokens.", status: :unprocessable_entity)
          end

          title = params[:title].presence || "Kazitua test"
          body = params[:body].presence || "Push pipeline check"
          data = params[:data].is_a?(ActionController::Parameters) ? params[:data].to_unsafe_h : (params[:data] || { kind: "test" })

          result = PushSender.send_to_user(user, title: title, body: body, data: data)
          audit!("user.test_push", user, sent_count: result.sent_count, failed_count: result.failed_count)

          render_success({
            sent_count: result.sent_count,
            failed_count: result.failed_count,
            ticket_ids: result.ticket_ids,
            errors: result.errors
          })
        end

        def unsuspend
          user = User.find(params[:id])

          return render_error("not_suspended", "User is not currently suspended.", status: :unprocessable_entity) unless user.suspended?

          user.unsuspend!
          audit!("user.unsuspend", user)

          render_success({ user: AdminUserSerializer.render(user.reload) })
        end

        private

        def apply_search(scope, query)
          return scope if query.blank?

          like = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
          scope.where(
            "users.email ILIKE :q OR users.phone ILIKE :q OR " \
            "worker_profiles.first_name ILIKE :q OR worker_profiles.last_name ILIKE :q OR " \
            "employer_profiles.contact_name ILIKE :q OR employer_profiles.company_name ILIKE :q",
            q: like
          )
        end

        def apply_role(scope, role)
          return scope if role.blank?
          return scope unless User.roles.key?(role.to_s)

          scope.where(users: { role: role })
        end

        def apply_suspended(scope, suspended)
          case suspended.to_s
          when "true"
            scope.where.not(users: { suspended_at: nil })
          when "false"
            scope.where(users: { suspended_at: nil })
          else
            scope
          end
        end
      end
    end
  end
end
