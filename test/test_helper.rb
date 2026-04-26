ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  self.use_transactional_tests = true
end

class ActionDispatch::IntegrationTest
  def json
    JSON.parse(response.body)
  end

  def data
    json.fetch("data")
  end

  def error
    json.fetch("error")
  end

  def auth_headers(user)
    token, = UserSession.issue_for!(user, user_agent: "test", ip_address: "127.0.0.1")
    { "Authorization" => "Bearer #{token}" }
  end

  def create_worker(phone: unique_phone, email: nil)
    User.create!(phone: phone, email: email, role: "worker", phone_verified: true)
  end

  def create_employer(phone: unique_phone, verified: false)
    user = User.create!(phone: phone, role: "employer", phone_verified: true)
    user.create_employer_profile!(
      company_name: "Build #{SecureRandom.hex(3)}",
      contact_name: "Owner",
      city: "Toronto",
      verified: verified,
      verification_status: verified ? "approved" : "pending",
      verification_step: verified ? 4 : 3
    )
    user
  end

  def create_admin(phone: unique_phone)
    User.create!(phone: phone, role: "admin", phone_verified: true)
  end

  def create_job(employer:, title: "Carpenter needed")
    employer.jobs.create!(
      title: title,
      trade: "Carpenter",
      location: "Toronto - Central",
      description: "Frame walls",
      pay_min_cents: 3_000,
      pay_max_cents: 4_000,
      job_type: "Full-time",
      duration: "Ongoing",
      status: "active",
      published_at: Time.current,
      expires_at: 30.days.from_now
    )
  end

  def unique_phone
    "416#{SecureRandom.random_number(10_000_000).to_s.rjust(7, "0")}"
  end
end
