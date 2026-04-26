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
          profile.assign_attributes(profile_attributes)

          if profile.save
            render_success(EmployerProfileSerializer.render(profile))
          else
            render_error("profile_invalid", profile.errors.full_messages.to_sentence, status: :unprocessable_entity)
          end
        end

        private

        def profile_attributes
          {
            company_name: params[:companyName],
            contact_name: params[:contactName],
            company_size: params[:companySize],
            industry_type: params[:industryType],
            website: params[:website],
            description: params[:description] || params[:bio],
            city: params[:headquarters] || params[:city],
            service_areas: array_param(:serviceAreas),
            benefits: array_param(:benefits)
          }
        end

        def array_param(key)
          value = params[key]
          return [] unless value.is_a?(Array)

          value.filter_map { |item| item.to_s.strip.presence }
        end
      end
    end
  end
end
