module Api
  module V1
    module Auth
      class OtpController < ApplicationController
        VALID_ROLES = %w[worker employer].freeze

        def start
          phone = normalize_phone(params[:phone])
          return render_error("invalid_phone", "Enter a valid 10 digit Canadian phone number.", status: :unprocessable_entity) unless phone.length == 10

          purpose = params[:purpose].presence_in(%w[login signup]) || "login"
          requested_role = params[:role].presence_in(VALID_ROLES)
          user = User.find_by(phone: phone)

          if purpose == "login" && user.nil?
            return render_error("account_not_found", "No account exists for that phone number.", status: :not_found)
          end

          if purpose == "signup" && user.present? && requested_role.present? && user.role != requested_role
            return render_error("role_mismatch", "That phone number already belongs to a different account type.", status: :conflict)
          end

          code = OtpChallenge.generate_code
          challenge = OtpChallenge.create!(
            user: user,
            phone: phone,
            purpose: purpose,
            requested_role: requested_role,
            code_digest: OtpChallenge.digest(code),
            expires_at: OtpChallenge::TTL.from_now
          )

          OtpDelivery::Sms.deliver!(phone: phone, code: code)

          payload = {
            challenge_id: challenge.id,
            expires_at: challenge.expires_at
          }
          payload[:development_code] = code unless Rails.env.production?

          render_success(payload, status: :created)
        rescue OtpDelivery::Sms::DeliveryError => error
          Rails.logger.warn("OTP delivery failed: #{error.message}")
          render_error("otp_delivery_failed", "Could not send verification code. Please try again.", status: :bad_gateway)
        end

        def verify
          challenge = OtpChallenge.active.find_by(id: params[:challenge_id])
          return render_error("challenge_not_found", "OTP challenge not found or expired.", status: :not_found) unless challenge

          code = params[:code].to_s.gsub(/\D/, "")
          return render_error("invalid_code", "Enter the 6 digit verification code.", status: :unprocessable_entity) unless code.length == OtpChallenge::CODE_LENGTH

          return render_error("incorrect_code", "Incorrect verification code.", status: :unauthorized) unless challenge.verify(code)

          is_new_user = challenge.user.nil?
          user = challenge.user || User.create!(
            phone: challenge.phone,
            role: challenge.requested_role.presence_in(VALID_ROLES) || "worker",
            phone_verified: true
          )
          user.update!(phone_verified: true)
          challenge.update!(user: user, consumed_at: Time.current)

          token, session = UserSession.issue_for!(
            user,
            user_agent: request.user_agent,
            ip_address: request.remote_ip
          )

          render_success(
            {
              token: token,
              session: {
                id: session.id,
                expires_at: session.expires_at
              },
              is_new_user: is_new_user,
              user: UserSerializer.render(user)
            }
          )
        end

        private

        def normalize_phone(value)
          value.to_s.gsub(/\D/, "").delete_prefix("1")
        end
      end
    end
  end
end
