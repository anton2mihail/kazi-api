module Api
  module V1
    class JobsController < ApplicationController
      before_action :authenticate_user!, except: []
      before_action :set_job, only: [:show, :update]

      def index
        jobs = Job.includes(employer: :employer_profile)
        jobs = current_user.employer? ? jobs.where("jobs.status = ? OR jobs.employer_id = ?", "active", current_user.id) : jobs.where(status: "active")
        jobs = jobs.order(published_at: :desc)
        jobs = jobs.where(trade: params[:trade]) if params[:trade].present? && params[:trade] != "All Trades"
        jobs = jobs.where(location: params[:location]) if params[:location].present? && params[:location] != "All Locations"
        jobs = jobs.where("title ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%") if params[:q].present?

        if current_user.employer?
          jobs = jobs.or(Job.where(employer_id: current_user.id))
        end

        applicant_counts = JobApplication.where(job_id: jobs.map(&:id)).group(:job_id).count
        render_success(JobSerializer.list(jobs, applicant_counts: applicant_counts))
      end

      def show
        render_success(JobSerializer.render(@job))
      end

      def create
        return unless require_role!(:employer)

        profile = current_user.employer_profile
        return render_error("employer_profile_required", "Create your employer profile before posting jobs.", status: :unprocessable_entity) unless profile
        return render_error("employer_not_verified", "Employer verification is required before posting jobs.", status: :forbidden) unless profile.verified?

        job = current_user.jobs.build(job_attributes.merge(status: "active", published_at: Time.current, expires_at: 30.days.from_now))
        if job.save
          render_success(JobSerializer.render(job), status: :created)
        else
          render_error("job_invalid", job.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def update
        return unless require_role!(:employer)
        return render_error("forbidden", "You can only update your own jobs.", status: :forbidden) unless @job.employer_id == current_user.id

        if @job.update(job_attributes.merge(published_at: Time.current, expires_at: 30.days.from_now))
          render_success(JobSerializer.render(@job))
        else
          render_error("job_invalid", @job.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      private

      def set_job
        @job = Job.includes(employer: :employer_profile).find(params[:id])
      end

      def job_attributes
        trade = params[:trade].presence || Array(params[:trades]).first
        {
          title: params[:title],
          trade: trade,
          location: params[:location],
          description: params[:description],
          pay_min_cents: money_param(:payMin),
          pay_max_cents: money_param(:payMax),
          job_type: params[:type] || params[:jobType],
          duration: params[:duration],
          hours_per_week: params[:hoursPerWeek],
          required_certifications: array_param(:requiredCerts),
          preferred_certifications: array_param(:preferredCerts),
          required_skills: array_param(:requiredSkills),
          preferred_skills: array_param(:preferredSkills),
          benefits: array_param(:benefits)
        }
      end

      def array_param(key)
        value = params[key]
        return [] unless value.is_a?(Array)

        value.filter_map { |item| item.to_s.strip.presence }
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
