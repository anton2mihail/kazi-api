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
          assign_user_attributes
          profile.assign_attributes(profile_attributes)

          if current_user.save && profile.save
            render_success(WorkerProfileSerializer.render(profile))
          else
            errors = current_user.errors.full_messages + profile.errors.full_messages
            render_error("profile_invalid", errors.to_sentence, status: :unprocessable_entity)
          end
        end

        private

        def assign_user_attributes
          return unless params.key?(:email)

          current_user.email = params[:email]
          current_user.email_verified = false if current_user.email_changed?
          current_user.email_verified = truthy_param?(:emailVerified) if params.key?(:emailVerified)
        end

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
            custom_certifications: array_param(:customCertifications),
            verified_certifications: array_param(:verifiedCerts),
            skills: array_param(:skills),
            skills_added_at: datetime_param(:skillsAddedAt),
            years_experience: years_experience_param,
            start_month: params[:startMonth],
            start_year: params[:startYear],
            hourly_rate_min_cents: money_param(:hourlyRateMin) || money_param(:hourlyRate),
            work_radius: params[:workRadius].presence || "30",
            has_transportation: boolean_param(:hasTransportation, default: true),
            has_own_tools: boolean_param(:hasOwnTools, default: false),
            driving_licenses: array_param(:drivingLicenses),
            gender: params[:gender],
            followed_company_ids: uuid_array_param(:followedCompanies),
            profile_updated_at: datetime_param(:profileUpdatedAt) || Time.current
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

        def years_experience_param
          return integer_param(:yearsExperience) if params[:yearsExperience].present?
          return nil if params[:startYear].blank?

          start_month = params[:startMonth].presence || "1"
          start_date = Date.new(params[:startYear].to_i, start_month.to_i.clamp(1, 12), 1)
          ((Date.current - start_date) / 365.25).floor.clamp(0, 80)
        rescue Date::Error
          nil
        end

        def money_param(key)
          value = params[key]
          return nil if value.blank?

          (BigDecimal(value.to_s) * 100).to_i
        rescue ArgumentError
          nil
        end

        def datetime_param(key)
          value = params[key]
          return nil if value.blank?

          Time.zone.parse(value.to_s)
        rescue ArgumentError, TypeError
          nil
        end

        def boolean_param(key, default:)
          return default unless params.key?(key)

          ActiveModel::Type::Boolean.new.cast(params[key])
        end

        def truthy_param?(key)
          ActiveModel::Type::Boolean.new.cast(params[key])
        end

        def uuid_array_param(key)
          array_param(key).filter_map do |value|
            value if value.match?(/\A[0-9a-fA-F-]{36}\z/)
          end
        end
      end
    end
  end
end
