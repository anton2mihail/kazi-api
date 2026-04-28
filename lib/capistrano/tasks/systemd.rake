namespace :systemd do
  def systemctl(service, command)
    sudo :systemctl, command, service
  end

  desc "Restart Kazitu API service"
  task :restart_api do
    on roles(:app) do
      systemctl "kazitu-api.service", "restart"
    end
  end

  desc "Restart Kazitu Sidekiq service"
  task :restart_sidekiq do
    on roles(:app) do
      systemctl "kazitu-sidekiq.service", "restart"
    end
  end

  desc "Show Kazitu API service status"
  task :status do
    on roles(:app) do
      systemctl "kazitu-api.service", "status"
      systemctl "kazitu-sidekiq.service", "status"
    end
  end
end
