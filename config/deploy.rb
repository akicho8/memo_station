# config valid only for current version of Capistrano
lock "3.20.0"

set :application, "memo_station"
set :repo_url, "file://#{Pathname(__dir__).dirname}"

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
set :branch, `git rev-parse --abbrev-ref HEAD`.strip

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, proc { "/var/www/#{fetch(:application)}_#{fetch(:stage)}" }

set :git_shallow_clone, 1

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", "config/secrets.yml"
append :linked_files, "config/master.key"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "vendor/bundle", "public/system"

namespace :deploy do
  # cap production deploy:master_key_upload
  desc "master.key をアップロード"
  before "check:linked_files", :master_key_upload do
    on roles(:all) do
      upload! "config/master.key", shared_path.join("config")
    end
  end
end

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :default_env, -> {
  {
    "DISABLE_DATABASE_ENVIRONMENT_CHECK" => "1",
    "RAILS_ENV"                          => fetch(:rails_env),
    # "PASSENGER_INSTANCE_REGISTRY_DIR"    => "/var/run/passenger-instreg",
  }
}

# Default value for keep_releases is 5
set :keep_releases, 1

# Bundler
set :bundle_config, { deployment: true }
set :bundle_flags, "" # --quiet を外して動作状況を確認する

# cap production passenger:restart
namespace :passenger do
  desc "Passenger の再起動"
  task :restart do
    if false
      # 本当は次のようにするべきだのだが Permission denied - connect(2) for /tmp/passenger.bmcU99g/agents.s/core_api (Errno::EACCES) のエラーになってしまう
      # 01 /opt/rbenv/versions/3.4.2/lib/ruby/gems/3.4.0/gems/passenger-6.0.26/src/ruby_supportlib/phusion_passenger/admin_tools/instance.rb:94:in "UNIXSocket#initialize": Permission denied - connect(2) for /tmp/passenger.bmcU99g/agents.s/core_api (Errno::EACCES)
      on roles(:app) do
        execute "passenger-config", "restart-app #{fetch(:deploy_to)} --ignore-app-not-running"
      end
    else
      # 単に自分ユーザーで再起動させる
      if true
        system "brew services restart httpd"
        system "brew services list | grep httpd"
      else
        system "apachectl restart"
      end
      if false
        sleep 1
        system "curl --silent -I http://memo/ | grep HTTP"
      else
        system "open http://memo/"
      end
    end
  end
end

# cap production deploy:restart
namespace :deploy do
  desc "再起動"
  task :restart do
    invoke("passenger:restart")
  end
  after :publishing, "deploy:restart"
end
