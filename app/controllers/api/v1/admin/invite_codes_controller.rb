module Api
  module V1
    module Admin
      class InviteCodesController < BaseController
        def index
          render_success(InviteCode.order(created_at: :desc).map { |invite| serialize(invite) })
        end

        def create
          invite = InviteCode.create!(
            code: params[:code].presence || unique_code,
            company_name: params[:companyName],
            contact_email: params[:contactEmail],
            pre_approved: ActiveModel::Type::Boolean.new.cast(params.fetch(:preApproved, true)),
            expires_at: datetime_param(:expiresAt)
          )
          audit!("invite_code.create", invite)
          render_success(serialize(invite), status: :created)
        rescue ActiveRecord::RecordInvalid => error
          render_error("invite_invalid", error.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end

        def update
          invite = InviteCode.find(params[:id])
          invite.update!(
            company_name: params[:companyName].presence || invite.company_name,
            contact_email: params.key?(:contactEmail) ? params[:contactEmail] : invite.contact_email,
            pre_approved: params.key?(:preApproved) ? ActiveModel::Type::Boolean.new.cast(params[:preApproved]) : invite.pre_approved,
            expires_at: params.key?(:expiresAt) ? datetime_param(:expiresAt) : invite.expires_at
          )
          audit!("invite_code.update", invite)
          render_success(serialize(invite))
        rescue ActiveRecord::RecordInvalid => error
          render_error("invite_invalid", error.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end

        private

        def serialize(invite)
          {
            id: invite.id,
            code: invite.code,
            companyName: invite.company_name,
            contactEmail: invite.contact_email,
            preApproved: invite.pre_approved,
            expiresAt: invite.expires_at,
            usedAt: invite.used_at,
            usedBy: invite.used_by_id,
            createdAt: invite.created_at,
            updatedAt: invite.updated_at
          }
        end

        def unique_code
          loop do
            code = InviteCode.generate_code
            return code unless InviteCode.exists?(code: code)
          end
        end

        def datetime_param(key)
          return nil if params[key].blank?

          Time.zone.parse(params[key].to_s)
        rescue ArgumentError, TypeError
          nil
        end
      end
    end
  end
end
