if Rails.env.production?
  puts "Skipping local demo seeds in production."
else

now = Time.zone.now

def upsert_user!(phone:, role:, email: nil, email_verified: false)
  user = User.find_or_initialize_by(phone: phone)
  user.assign_attributes(
    role: role,
    email: email,
    phone_verified: true,
    email_verified: email.present? && email_verified
  )
  user.save!
  user
end

def upsert_employer_profile!(user, attributes)
  profile = EmployerProfile.find_or_initialize_by(user: user)
  profile.assign_attributes(attributes)
  profile.save!
  profile
end

def upsert_worker_profile!(user, attributes)
  profile = WorkerProfile.find_or_initialize_by(user: user)
  profile.assign_attributes(attributes)
  profile.save!
  profile
end

def upsert_job!(employer, title:, attributes:)
  job = Job.find_or_initialize_by(employer: employer, title: title)
  job.assign_attributes(attributes.merge(title: title))
  job.save!
  job
end

def upsert_application!(job:, worker:, status:, cover_note:, created_at:)
  application = JobApplication.find_or_initialize_by(job: job, worker: worker)
  application.assign_attributes(status: status, cover_note: cover_note, created_at: created_at)
  application.withdrawn_at = created_at + 2.days if status == "withdrawn"
  application.save!
  application
end

admin = upsert_user!(
  phone: "4165550199",
  role: "admin",
  email: "admin@kazitu.local",
  email_verified: true
)

maple = upsert_user!(
  phone: "4165550201",
  role: "employer",
  email: "ops@maplebuild.local",
  email_verified: true
)
upsert_employer_profile!(
  maple,
  company_name: "Maple Build Co.",
  contact_name: "Olivia Chen",
  job_title: "Talent Operations Lead",
  email: "ops@maplebuild.local",
  phone: "4165550201",
  company_size: "51-200",
  industry_type: "Residential and commercial construction",
  website: "https://maplebuild.example",
  description: "General contractor running commercial interiors, residential infill, and mid-rise renovation projects across the GTA.",
  city: "Toronto - Central",
  office_locations: [ "Toronto - Central", "Mississauga" ],
  service_areas: [ "Toronto - Central", "Toronto - West", "Mississauga", "Hamilton" ],
  benefits: [ "Health & Dental", "Tool Allowance", "Safety Boot Allowance" ],
  social_media: { linkedin: "https://linkedin.example/maple-build" },
  verified: true,
  verification_status: "approved",
  verification_step: 4,
  verification_submitted_at: now - 20.days,
  verified_at: now - 19.days,
  verification_notes: "Local seed: approved employer account"
)

lakeview = upsert_user!(
  phone: "4165550202",
  role: "employer",
  email: "dispatch@lakeviewelectrical.local",
  email_verified: true
)
upsert_employer_profile!(
  lakeview,
  company_name: "Lakeview Electrical Ltd.",
  contact_name: "Noah Patel",
  job_title: "Field Coordinator",
  email: "dispatch@lakeviewelectrical.local",
  phone: "4165550202",
  company_size: "11-50",
  industry_type: "Electrical contracting",
  website: "https://lakeviewelectrical.example",
  description: "Licensed electrical contractor focused on commercial service, tenant improvements, and panel upgrades.",
  city: "Toronto - West",
  office_locations: [ "Toronto - West", "Oakville" ],
  service_areas: [ "Toronto - West", "Oakville", "Burlington", "Hamilton" ],
  benefits: [ "Company Vehicle", "Paid Training", "RRSP Matching" ],
  social_media: { linkedin: "https://linkedin.example/lakeview-electrical" },
  verified: true,
  verification_status: "approved",
  verification_step: 4,
  verification_submitted_at: now - 15.days,
  verified_at: now - 14.days,
  verification_notes: "Local seed: approved employer account"
)

northline = upsert_user!(
  phone: "4165550203",
  role: "employer",
  email: "owner@northlineforms.local",
  email_verified: true
)
upsert_employer_profile!(
  northline,
  company_name: "Northline Forms",
  contact_name: "Ethan Brooks",
  job_title: "Owner",
  email: "owner@northlineforms.local",
  phone: "4165550203",
  company_size: "2-10",
  industry_type: "Concrete and formwork",
  website: "https://northlineforms.example",
  description: "Small formwork crew awaiting verification before posting jobs.",
  city: "Vaughan",
  office_locations: [ "Vaughan" ],
  service_areas: [ "Vaughan", "Toronto - North", "Richmond Hill" ],
  benefits: [ "Overtime Available" ],
  social_media: {},
  verified: false,
  verification_status: "pending",
  verification_step: 3,
  verification_submitted_at: now - 2.days,
  verified_at: nil,
  verification_notes: "Local seed: pending review"
)

nadia = upsert_user!(
  phone: "4165550101",
  role: "worker",
  email: "nadia.carpenter@kazitu.local",
  email_verified: true
)
upsert_worker_profile!(
  nadia,
  first_name: "Nadia",
  last_name: "Khan",
  bio: "Red Seal carpenter with strong commercial framing and finish experience. Comfortable leading small crews and reading drawings.",
  primary_trade: "Carpenter",
  secondary_trades: [ "Finish Carpenter", "Formwork Carpenter" ],
  city: "Toronto - Central",
  province: "ON",
  work_areas: [ "Toronto - Central", "Toronto - West", "Mississauga" ],
  availability: [ "Full-time", "Weekdays", "Can start this week" ],
  certifications: [ "Working at Heights", "WHMIS 2015", "First Aid/CPR" ],
  custom_certifications: [ "Powder Actuated Tools" ],
  verified_certifications: [ "Working at Heights", "WHMIS 2015" ],
  skills: [ "Framing", "Finish carpentry", "Blueprint reading", "Trim/molding" ],
  skills_added_at: now - 25.days,
  years_experience: 8,
  start_month: "4",
  start_year: "2018",
  hourly_rate_min_cents: 3_800,
  work_radius: "50",
  has_transportation: true,
  has_own_tools: true,
  driving_licenses: [ "G", "Forklift" ],
  gender: "Prefer not to say",
  followed_company_ids: [ maple.id ],
  profile_updated_at: now - 3.days
)

marco = upsert_user!(
  phone: "4165550102",
  role: "worker",
  email: "marco.electrician@kazitu.local",
  email_verified: true
)
upsert_worker_profile!(
  marco,
  first_name: "Marco",
  last_name: "Rivera",
  bio: "Licensed 309A electrician with commercial service, lighting retrofit, and panel upgrade experience.",
  primary_trade: "Electrician (Licensed)",
  secondary_trades: [ "Electrician (Apprentice)", "Estimator" ],
  city: "Toronto - West",
  province: "ON",
  work_areas: [ "Toronto - West", "Oakville", "Burlington" ],
  availability: [ "Full-time", "Evenings", "Emergency calls" ],
  certifications: [ "309A C of Q", "WHMIS 2015", "First Aid/CPR", "Arc Flash Training" ],
  custom_certifications: [],
  verified_certifications: [ "309A C of Q", "WHMIS 2015" ],
  skills: [ "Commercial wiring", "Panel upgrades", "Troubleshooting", "Conduit bending" ],
  skills_added_at: now - 18.days,
  years_experience: 6,
  start_month: "6",
  start_year: "2020",
  hourly_rate_min_cents: 4_600,
  work_radius: "40",
  has_transportation: true,
  has_own_tools: true,
  driving_licenses: [ "G" ],
  gender: "Male",
  followed_company_ids: [ lakeview.id ],
  profile_updated_at: now - 1.day
)

priya = upsert_user!(
  phone: "4165550103",
  role: "worker",
  email: "priya.plumber@kazitu.local",
  email_verified: false
)
upsert_worker_profile!(
  priya,
  first_name: "Priya",
  last_name: "Sharma",
  bio: "Journeyperson plumber experienced in service work, rough-ins, and backflow testing.",
  primary_trade: "Plumber (Licensed)",
  secondary_trades: [ "Pipefitter / Steamfitter" ],
  city: "Toronto - West",
  province: "ON",
  work_areas: [ "Toronto - West", "Brampton", "Mississauga" ],
  availability: [ "Full-time", "Weekends" ],
  certifications: [ "306A C of Q", "WHMIS 2015", "Backflow Prevention" ],
  custom_certifications: [ "G2 Gas License" ],
  verified_certifications: [ "306A C of Q" ],
  skills: [ "Residential plumbing", "Drain cleaning", "Backflow testing", "Hydronic heating" ],
  skills_added_at: now - 12.days,
  years_experience: 7,
  start_month: "9",
  start_year: "2019",
  hourly_rate_min_cents: 4_200,
  work_radius: "35",
  has_transportation: true,
  has_own_tools: false,
  driving_licenses: [ "G", "DZ" ],
  gender: "Female",
  followed_company_ids: [ maple.id, lakeview.id ],
  profile_updated_at: now - 6.hours
)

darnell = upsert_user!(
  phone: "4165550104",
  role: "worker",
  email: nil,
  email_verified: false
)
upsert_worker_profile!(
  darnell,
  first_name: "Darnell",
  last_name: "Washington",
  bio: "Reliable general labourer with concrete, demolition, and material handling experience.",
  primary_trade: "General Labourer",
  secondary_trades: [ "Concrete Finisher", "Demolition Worker" ],
  city: "Hamilton",
  province: "ON",
  work_areas: [ "Hamilton", "Burlington", "St. Catharines" ],
  availability: [ "Contract", "Early mornings" ],
  certifications: [ "Working at Heights", "WHMIS 2015" ],
  custom_certifications: [],
  verified_certifications: [ "WHMIS 2015" ],
  skills: [ "Site cleanup", "Material handling", "Concrete pouring", "Interior demo" ],
  skills_added_at: now - 30.days,
  years_experience: 3,
  start_month: "5",
  start_year: "2023",
  hourly_rate_min_cents: 2_800,
  work_radius: "30",
  has_transportation: false,
  has_own_tools: false,
  driving_licenses: [],
  gender: "Male",
  followed_company_ids: [],
  profile_updated_at: now - 9.days
)

jobs = {
  finish_carpenter: upsert_job!(
    maple,
    title: "Finish Carpenter - Condo Lobby",
    attributes: {
      trade: "Carpenter",
      location: "Toronto - Central",
      description: "High-end lobby renovation requiring trim, panel installation, doors, and punch-list work.",
      pay_min_cents: 3_700,
      pay_max_cents: 4_500,
      job_type: "Full-time",
      duration: "6 weeks",
      hours_per_week: "40+ hrs/week",
      required_certifications: [ "Working at Heights", "WHMIS 2015" ],
      preferred_certifications: [ "First Aid/CPR" ],
      required_skills: [ "Finish carpentry", "Blueprint reading" ],
      preferred_skills: [ "Trim/molding", "Cabinet installation" ],
      benefits: [ "Tool Allowance", "Safety Boot Allowance" ],
      urgent: true,
      status: "active",
      published_at: now - 5.hours,
      expires_at: now + 30.days
    }
  ),
  formwork: upsert_job!(
    maple,
    title: "Formwork Carpenter - Parking Structure",
    attributes: {
      trade: "Formwork Carpenter",
      location: "Mississauga",
      description: "Commercial concrete project. Gang form and shoring experience preferred.",
      pay_min_cents: 3_500,
      pay_max_cents: 4_200,
      job_type: "Contract",
      duration: "3 months",
      hours_per_week: "40+ hrs/week",
      required_certifications: [ "Working at Heights", "WHMIS 2015", "Fall Arrest" ],
      preferred_certifications: [ "Scaffolding" ],
      required_skills: [ "Gang form assembly", "Shoring" ],
      preferred_skills: [ "Blueprint reading" ],
      benefits: [ "Overtime Available" ],
      urgent: false,
      status: "active",
      published_at: now - 2.days,
      expires_at: now + 24.days
    }
  ),
  electrical: upsert_job!(
    lakeview,
    title: "Licensed Electrician - Tenant Improvements",
    attributes: {
      trade: "Electrician (Licensed)",
      location: "Toronto - West",
      description: "Commercial tenant improvement work including branch wiring, panel tie-ins, and lighting controls.",
      pay_min_cents: 4_400,
      pay_max_cents: 5_400,
      job_type: "Full-time",
      duration: "Ongoing",
      hours_per_week: "40+ hrs/week",
      required_certifications: [ "309A C of Q", "WHMIS 2015" ],
      preferred_certifications: [ "Arc Flash Training" ],
      required_skills: [ "Commercial wiring", "Panel upgrades" ],
      preferred_skills: [ "Troubleshooting", "Low voltage" ],
      benefits: [ "Company Vehicle", "Paid Training" ],
      urgent: false,
      status: "active",
      published_at: now - 8.hours,
      expires_at: now + 29.days
    }
  ),
  apprentice: upsert_job!(
    lakeview,
    title: "Electrical Apprentice - 3rd Year",
    attributes: {
      trade: "Electrician (Apprentice)",
      location: "Oakville",
      description: "Residential and light commercial jobs with a licensed lead. Strong conduit and rough-in basics required.",
      pay_min_cents: 2_400,
      pay_max_cents: 3_000,
      job_type: "Full-time",
      duration: "Ongoing",
      hours_per_week: "30-40 hrs/week",
      required_certifications: [ "WHMIS 2015" ],
      preferred_certifications: [ "Working at Heights" ],
      required_skills: [ "Wire pulling", "Outlet installation" ],
      preferred_skills: [ "Conduit bending" ],
      benefits: [ "Paid Training" ],
      urgent: false,
      status: "active",
      published_at: now - 1.day,
      expires_at: now + 25.days
    }
  ),
  archived_plumber: upsert_job!(
    maple,
    title: "Service Plumber - Completed Local Seed",
    attributes: {
      trade: "Plumber (Licensed)",
      location: "Toronto - West",
      description: "Archived seed job used to test closed history and employer management states.",
      pay_min_cents: 3_800,
      pay_max_cents: 4_800,
      job_type: "Contract",
      duration: "2 weeks",
      hours_per_week: "30-40 hrs/week",
      required_certifications: [ "306A C of Q", "WHMIS 2015" ],
      preferred_certifications: [ "Backflow Prevention" ],
      required_skills: [ "Residential plumbing", "Drain cleaning" ],
      preferred_skills: [ "Hydronic heating" ],
      benefits: [],
      urgent: false,
      status: "closed",
      published_at: now - 45.days,
      expires_at: now - 15.days,
      closed_at: now - 12.days,
      archived_at: now - 12.days
    }
  )
}

applications = [
  upsert_application!(
    job: jobs[:finish_carpenter],
    worker: nadia,
    status: "shortlisted",
    cover_note: "I can start this week and have the finish tools needed for lobby millwork.",
    created_at: now - 4.hours
  ),
  upsert_application!(
    job: jobs[:electrical],
    worker: marco,
    status: "interview_requested",
    cover_note: "Available for tenant improvement work and comfortable with live commercial environments.",
    created_at: now - 6.hours
  ),
  upsert_application!(
    job: jobs[:finish_carpenter],
    worker: priya,
    status: "pending",
    cover_note: "I am primarily a plumber, but can help with fixture coordination and punch-list support.",
    created_at: now - 2.hours
  ),
  upsert_application!(
    job: jobs[:formwork],
    worker: darnell,
    status: "reviewing",
    cover_note: "Strong concrete background and available for the full project window.",
    created_at: now - 1.day
  )
]

InterviewRequest.find_or_initialize_by(employer: lakeview, worker: marco, job: jobs[:electrical]).tap do |request|
  request.assign_attributes(
    message: "Can you meet our site supervisor tomorrow morning at 8:30?",
    status: "pending"
  )
  request.save!
end

InterviewRequest.find_or_initialize_by(employer: maple, worker: nadia, job: jobs[:finish_carpenter]).tap do |request|
  request.assign_attributes(
    message: "Accepted contact reveal for the seeded shortlisted carpenter.",
    status: "accepted",
    responded_at: now - 1.hour
  )
  request.save!
end

WorkHistory.find_or_initialize_by(job: jobs[:archived_plumber], worker: priya).tap do |history|
  history.assign_attributes(
    employer: maple,
    employer_name: "Maple Build Co.",
    job_title: jobs[:archived_plumber].title,
    status: "verified",
    worker_marked_at: now - 10.days,
    employer_responded_at: now - 9.days,
    worker_rating: 5,
    employer_rating: 5,
    worker_review: "Clear scope and quick payment.",
    employer_review: "Reliable, clean work, and strong communication.",
    employer_confirmed: true
  )
  history.save!
end

WorkHistory.find_or_initialize_by(job: jobs[:formwork], worker: darnell).tap do |history|
  history.assign_attributes(
    employer: maple,
    employer_name: "Maple Build Co.",
    job_title: jobs[:formwork].title,
    status: "pending_employer",
    worker_marked_at: now - 1.day,
    auto_verify_at: now + WorkHistory::AUTO_VERIFY_DAYS.days,
    worker_rating: 4,
    worker_review: "Crew was organized and safety orientation was clear."
  )
  history.save!
end

[
  [ nadia, "application_update", "Application shortlisted", "Maple Build Co. shortlisted you for Finish Carpenter - Condo Lobby.", jobs[:finish_carpenter], nil ],
  [ marco, "interview_request", "Interview requested", "Lakeview Electrical requested an interview for Tenant Improvements.", jobs[:electrical], nil ],
  [ priya, "work_history", "Work history verified", "Maple Build Co. verified your completed service plumbing work.", jobs[:archived_plumber], now - 8.days ],
  [ maple, "new_application", "New applicant", "Nadia Khan applied to Finish Carpenter - Condo Lobby.", jobs[:finish_carpenter], nil ]
].each do |user, notification_type, title, message, job, read_at|
  Notification.find_or_initialize_by(user: user, notification_type: notification_type, title: title, job: job).tap do |notification|
    notification.assign_attributes(message: message, company_id: job&.employer_id, read_at: read_at)
    notification.save!
  end
end

[ admin, maple, lakeview, northline, nadia, marco, priya, darnell ].each do |user|
  NotificationPreference.find_or_create_by!(user: user)
end

Report.find_or_initialize_by(reporter: nadia, job: jobs[:apprentice], reason: "misleading_pay").tap do |report|
  report.assign_attributes(
    details: "Seeded report: applicant says pay range should be confirmed before interview.",
    status: "pending",
    target_type: "Job",
    target_id: jobs[:apprentice].id
  )
  report.save!
end

Report.find_or_initialize_by(reporter: maple, reason: "no_show", target_type: "User", target_id: darnell.id).tap do |report|
  report.assign_attributes(
    details: "Seeded employer report for admin queue testing.",
    status: "reviewed",
    reviewed_by: admin,
    reviewed_at: now - 3.hours,
    admin_notes: "Local seed: reviewed report"
  )
  report.save!
end

InviteCode.find_or_initialize_by(code: "MAPLE1").tap do |invite|
  invite.assign_attributes(
    company_name: "Maple Build Co.",
    contact_email: "ops@maplebuild.local",
    pre_approved: true,
    expires_at: now + 60.days
  )
  invite.save!
end

InviteCode.find_or_initialize_by(code: "TRADES").tap do |invite|
  invite.assign_attributes(
    company_name: "Local Trades Demo",
    contact_email: "demo@kazitu.local",
    pre_approved: true,
    expires_at: now + 60.days
  )
  invite.save!
end

unless Rails.env.test?
  puts "Seeded #{User.count} users, #{EmployerProfile.count} employer profiles, #{WorkerProfile.count} worker profiles."
  puts "Seeded #{Job.count} jobs, #{JobApplication.count} applications, #{InterviewRequest.count} interview requests."
  puts "Local login phones:"
  puts "  Worker Nadia:   416-555-0101"
  puts "  Worker Marco:   416-555-0102"
  puts "  Worker Priya:   416-555-0103"
  puts "  Employer Maple: 416-555-0201"
  puts "  Employer Lake:  416-555-0202"
  puts "  Pending Emp:    416-555-0203"
  puts "Use the development OTP returned by /api/v1/auth/otp/start when logging in locally."
end
end
