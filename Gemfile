source 'https://rubygems.org'

gem 'jbundler', platform: :jruby
gem 'rails', github: "edpaget/rails", branch: "4-2-stable"
gem 'postgres_ext', '~> 2.4.0'
gem 'active_record_union', github: "edpaget/active_record_union", branch: "union-all"
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'doorkeeper', '~> 1.4.1'
gem 'devise', '~> 3.0'
gem 'versionist', '~> 1.0'
gem 'rack-cors', '~> 0.3', require: 'rack/cors'
gem 'restpack_serializer', github: "edpaget/restpack_serializer", branch: "dev"
gem 'paper_trail', '~> 3.0'
gem 'omniauth', '~> 1.0'
gem 'omniauth-facebook', '~> 2.0'
gem 'omniauth-gplus', '~> 2.0'
gem 'puma', '~> 2.0'
gem 'logstasher', '~> 0.6'
gem 'honeybadger', '~> 2.0'
gem 'jquery-rails', '~> 4.0'
gem 'uglifier', '~> 2.0'
gem 'sidekiq', '~> 3.0'
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'aws-sdk-v1', '~> 1.0'
gem 'json-schema', '~> 2.0'
gem 'p3p', '~> 1.0'
gem 'newrelic_rpm', '~> 3.0'
gem 'firebase_token_generator', '~> 2.0'
gem 'stringex', '~> 2.0'
gem 'faraday', '~> 0.9'
gem 'faraday_middleware', '~> 0.9'
gem 'faraday-http-cache', '~> 1.0'
gem 'activerecord-import', '~> 0.8'
gem 'schema_plus_pg_indexes', '~> 0.1'
gem 'rack-timeout', '~> 0.2'

platforms :jruby do
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'activerecord-jdbcmysql-adapter'
  gem 'therubyrhino'
  gem 'jruby-kafka', '1.0.0.beta'
end

platforms :ruby do
  gem 'therubyracer', '~> 0.12'
  gem 'pg', '~> 0.18'
  gem 'poseidon', '~> 0.0.5'
  gem 'mysql2', '~> 0.3'
end

group :development do
  gem 'spring'
  gem 'fig_rake', '~> 0.9.3'
  gem 'sqlite3', platform: :ruby
  gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
end

group :development, :test do
  gem 'foreman'
  gem 'database_cleaner', '~> 1.2.0'
  gem 'rspec', '~> 3.3.0'
  gem 'rspec-rails', '~> 3.3.0'
  gem 'guard-rspec', '~> 4.2.9', require: false
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'spring-commands-rspec', '~> 1.0.2'
  gem 'pry-rails', '~> 0.3.2'
end
