module Api
  module V1
    module Employers
      class ProfilesController < ApplicationController
        before_action :authenticate_user!
        before_action -> { require_role!(:employer) }

        def show
          render_success(EmployerProfileSerializer.render(current_user.employer_profile))
        end

        def update
          profile = current_user.employer_profile || current_user.build_employer_profile
          assign_user_attributes
          profile.assign_attributes(profile_attributes)

          if current_user.save && profile.save
            render_success(EmployerProfileSerializer.render(profile))
          else
            errors = current_user.errors.full_messages + profile.errors.full_messages
            render_error("profile_invalid", errors.to_sentence, status: :unprocessable_entity)
          end
        end

        private

        def assign_user_attributes
          return unless params.key?(:email)

          current_user.email = params[:email]
        end

        def profile_attributes
          {
            company_name: params[:companyName],
            contact_name: params[:contactName],
            job_title: params[:jobTitle],
            email: params[:email],
            phone: normalize_phone(params[:phone]).presence || current_user.phone,
            company_size: params[:companySize],
            industry_type: params[:industryType],
            website: params[:website],
            description: params[:description] || params[:bio],
            city: params[:headquarters] || params[:city],
            office_locations: array_param(:officeLocations),
            service_areas: array_param(:serviceAreas),
            benefits: array_param(:benefits),
            social_media: social_media_param,
            verification_submitted_at: current_user.employer_profile&.verification_submitted_at || Time.current
          }
        end

        def array_param(key)
          value = params[key]
          return [] unless value.is_a?(Array)

          value.filter_map { |item| item.to_s.strip.presence }
        end

        def social_media_param
          value = params[:socialMedia]
          return {} unless value.respond_to?(:to_unsafe_h) || value.is_a?(Hash)

          value.to_unsafe_h.slice("linkedin", "instagram", "facebook").transform_values { |item| item.to_s.strip }
        end

        def normalize_phone(value)
          value.to_s.gsub(/\D/, "").delete_prefix("1")
        end
      end
    end
  end
end
