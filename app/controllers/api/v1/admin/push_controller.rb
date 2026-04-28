module Api
  module V1
    module Admin
      class PushController < BaseController
        MAX_RECIPIENTS = 5_000
        MAX_PER_PAGE = 100
        DEFAULT_PER_PAGE = 20

        def broadcast
          title = params[:title].to_s.strip
          body = params[:body].to_s.strip

          if title.blank? || body.blank?
            return render_error("missing_message", "title and body are required.", status: :unprocessable_entity)
          end

          data = normalize_data(params[:data])
          filter = normalize_filter(params[:filter])

          users = resolve_users(filter)
          tokens = DeviceToken.active.where(user_id: users.select(:id)).pluck(:expo_push_token).uniq

          if tokens.empty?
            return render_error("no_active_devices", "No active device tokens matched the filter.", status: :unprocessable_entity)
          end

          if tokens.size > MAX_RECIPIENTS
            return render_error(
              "too_many_recipients",
              "Resolved #{tokens.size} recipients, exceeds the safety cap of #{MAX_RECIPIENTS}.",
              status: :unprocessable_entity
            )
          end

          result = PushSender.send_to_tokens(tokens, title: title, body: body, data: data)

          audit!(
            "admin.push.broadcast",
            current_user,
            recipient_count: tokens.size,
            sent_count: result.sent_count,
            failed_count: result.failed_count,
            ticket_count: result.ticket_ids.length,
            filter: filter
          )

          render_success({
            recipient_count: tokens.size,
            sent_count: result.sent_count,
            failed_count: result.failed_count,
            ticket_count: result.ticket_ids.length,
            errors: result.errors
          })
        end

        def history
          page = [ params[:page].to_i, 1 ].max
          per_page = params[:per_page].to_i
          per_page = DEFAULT_PER_PAGE if per_page <= 0
          per_page = [ per_page, MAX_PER_PAGE ].min

          scope = AuditLog.where(action: "admin.push.broadcast").includes(:actor).order(created_at: :desc, id: :desc)
          total = scope.count
          logs = scope.offset((page - 1) * per_page).limit(per_page)

          render_success({
            history: logs.map { |log| serialize_history_entry(log) },
            meta: {
              page: page,
              per_page: per_page,
              total: total,
              total_pages: (total.to_f / per_page).ceil
            }
          })
        end

        private

        def normalize_data(value)
          case value
          when ActionController::Parameters then value.to_unsafe_h
          when Hash then value
          else { kind: "broadcast" }
          end
        end

        def normalize_filter(value)
          hash =
            case value
            when ActionController::Parameters then value.to_unsafe_h
            when Hash then value
            else {}
            end
          hash.with_indifferent_access
        end

        def resolve_users(filter)
          scope = User.all
          explicit_ids = filter[:user_ids].is_a?(Array) && filter[:user_ids].any?

          scope = scope.where(id: filter[:user_ids]) if explicit_ids

          role = filter[:role].to_s
          if User.roles.key?(role)
            scope = scope.where(role: role)
          elsif !explicit_ids
            scope = scope.where(role: "worker")
          end

          case filter[:suspended]
          when true, "true"
            scope.where.not(suspended_at: nil)
          when false, "false"
            scope.where(suspended_at: nil)
          else
            explicit_ids ? scope : scope.where(suspended_at: nil)
          end
        end

        def serialize_history_entry(log)
          metadata = log.metadata || {}

          {
            id: log.id,
            created_at: log.created_at,
            recipient_count: metadata["recipient_count"] || metadata[:recipient_count] || 0,
            sent_count: metadata["sent_count"] || metadata[:sent_count] || 0,
            failed_count: metadata["failed_count"] || metadata[:failed_count] || 0,
            ticket_count: metadata["ticket_count"] || metadata[:ticket_count] || 0,
            filter: metadata["filter"] || metadata[:filter] || {},
            actor: serialize_actor(log.actor)
          }
        end

        def serialize_actor(actor)
          return nil if actor.nil?

          {
            id: actor.id,
            phone: actor.phone,
            role: actor.role
          }
        end
      end
    end
  end
end
