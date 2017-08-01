app_path = File.expand_path(File.dirname(File.dirname(__FILE__)))

pidfile "#{app_path}/tmp/pids/server.pid"

dev_env = 'development'
rails_env = ENV['RAILS_ENV'] || dev_env
port = rails_env == dev_env ? 3000 : 81
environment rails_env
state_path "#{app_path}/tmp/pids/puma.state"

if rails_env == "production"
  stdout_redirect "#{app_path}/log/production.log", "#{app_path}/log/production_err.log", true
end

bind "tcp://0.0.0.0:#{port}"

# Code to run before doing a restart. This code should
# close log files, database connections, etc.
#
# This can be called multiple times to add code each time.
#
# on_restart do
#   puts 'On restart...'
# end

# === Cluster mode ===
case rails_env
when "production"
  workers 2
  threads 0,8
when "staging"
  workers 2
  threads 0,4
end

# Code to run when a worker boots to setup the process before booting
# the app.
#
# This can be called multiple times to add hooks.
#
on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end

  # manually start new relic agent in staging
  # https://github.com/puma/puma/issues/614#issuecomment-117712457
  if rails_env == "staging"
    NewRelic::Agent.manual_start
  end
end

before_fork do
  ActiveRecord::Base.connection_pool.disconnect!
end

preload_app!

# Additional text to display in process listing
#
tag 'panoptes_api'
#
# If you do not specify a tag, Puma will infer it. If you do not want Puma
# to add a tag, use an empty string.

# Verifies that all workers have checked in to the master process within
# the given timeout. If not the worker process will be restarted. Default
# value is 60 seconds.
#
# worker_timeout 60

# Change the default worker timeout for booting
#
# If unspecified, this defaults to the value of worker_timeout.
#
# worker_boot_timeout 60
