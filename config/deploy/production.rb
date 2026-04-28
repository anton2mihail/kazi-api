server ENV.fetch("KAZITU_API_PRODUCTION_HOST", "172.105.99.206"),
  user: ENV.fetch("KAZITU_API_PRODUCTION_USER", "deploy"),
  roles: %w[app db web]

set :rails_env, "production"
set :deploy_to, ENV.fetch("KAZITU_API_DEPLOY_TO", "/home/deploy/apps/kazitu-api")
set :branch, ENV.fetch("BRANCH", ENV.fetch("DEPLOY_BRANCH", "main"))

after "deploy:publishing", "systemd:restart_api"
after "deploy:publishing", "systemd:restart_sidekiq"
