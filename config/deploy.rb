# config valid only for current version of Capistrano
lock '3.17.2'

set :application, "memo_station"
set :repo_url, "file://#{Pathname(__dir__).dirname}"

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp

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
# set :linked_files, fetch(:linked_files, []).push('config/database.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

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
# set :keep_releases, 5

# set :bundle_path, nil
set :bundle_flags, '--deployment'


# namespace :deploy do
#   desc 'Restart application'
#   task :restart do
#     on roles(:app) do
#       execute "passenger-config", "restart-app #{fetch(:deploy_to)} --ignore-app-not-running"
#     end
#     # system "passenger-config restart-app #{fetch(:deploy_to)} --ignore-app-not-running"
#   end
# end

