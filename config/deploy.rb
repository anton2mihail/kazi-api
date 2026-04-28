lock "~> 3.20.0"

set :application, "kazitu-api"
set :repo_url, ENV.fetch("KAZITU_API_REPO_URL", "git@github.com:anton2mihail/kazi-api.git")
set :deploy_to, ENV.fetch("KAZITU_API_DEPLOY_TO", "/home/deploy/apps/kazitu-api")
set :branch, ENV.fetch("BRANCH", ENV.fetch("DEPLOY_BRANCH", "main"))
set :format, :airbrussh
set :log_level, :info
set :pty, false
set :keep_releases, 5

append :linked_files, "config/master.key"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "storage", "public/system"

set :rbenv_type, :user
set :rbenv_ruby, ENV.fetch("RBENV_RUBY_VERSION", "3.4.7")
set :bundle_jobs, 4
set :bundle_path, -> { shared_path.join("bundle") }
set :bundle_without, []
set :migration_role, :db
set :conditionally_migrate, true
set :rails_env, "production"
set :default_env, {
  "RAILS_ENV" => "production",
  "BUNDLE_WITHOUT" => ""
}

namespace :deploy do
  desc "Upload linked files if they do not exist yet"
  task :ensure_linked_files do
    on roles(:app) do
      execute :mkdir, "-p", shared_path.join("config")
      unless test("[ -f #{shared_path.join('config/master.key')} ]")
        warn "Missing #{shared_path.join('config/master.key')}. Upload it before the first deploy."
      end
    end
  end
end

before "deploy:check:linked_files", "deploy:ensure_linked_files"
