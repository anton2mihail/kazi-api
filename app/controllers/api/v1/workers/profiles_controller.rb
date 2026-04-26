module Api
  module V1
    module Workers
      class ProfilesController < ApplicationController
        before_action :authenticate_user!
        before_action -> { require_role!(:worker) }

        def show
          render_success(WorkerProfileSerializer.render(current_user.worker_profile))
        end

        def update
          profile = current_user.worker_profile || current_user.build_worker_profile
          profile.assign_attributes(profile_attributes)

          if profile.save
            render_success(WorkerProfileSerializer.render(profile))
          else
            render_error("profile_invalid", profile.errors.full_messages.to_sentence, status: :unprocessable_entity)
          end
        end

        private

        def profile_attributes
          trades = array_param(:trades)
          {
            first_name: params[:firstName],
            last_name: params[:lastName],
            bio: params[:bio],
            primary_trade: trades.first,
            secondary_trades: trades.drop(1),
            city: params[:location] || params[:city],
            province: params[:province].presence || "ON",
            work_areas: array_param(:workAreas),
            availability: array_param(:availability),
            certifications: array_param(:certifications),
            skills: array_param(:skills),
            years_experience: integer_param(:yearsExperience),
            hourly_rate_min_cents: money_param(:hourlyRateMin) || money_param(:hourlyRate)
          }
        end

        def array_param(key)
          value = params[key]
          return [] unless value.is_a?(Array)

          value.filter_map { |item| item.to_s.strip.presence }
        end

        def integer_param(key)
          value = params[key]
          return nil if value.blank?

          value.to_i
        end

        def money_param(key)
          value = params[key]
          return nil if value.blank?

          (BigDecimal(value.to_s) * 100).to_i
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
