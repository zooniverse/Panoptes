# frozen_string_literal: true

def next?
  File.basename(__FILE__) == 'Gemfile.next'
end

source 'https://rubygems.org'

gem 'active_interaction', '~> 3.7.1'
gem 'active_model_serializers', '0.10.0.rc2' # Event stream
gem 'active_record_union', '~> 1.3.0'
gem 'activerecord-import', '~> 1.0'
gem 'aws-sdk', '~> 2.10'
gem 'congestion', git: 'https://github.com/camallen/Congestion.git', branch: 'ttl-freshly-added-keys', ref: '6bf0ffa7b2'
gem 'dalli'
gem 'deep_cloneable', '~> 2.3.2'
gem 'devise', '~> 4.7'
gem 'doorkeeper', '~> 4.4'
gem 'doorkeeper-jwt', '~> 0.2.1'
gem 'faraday', '~> 0.15'
gem 'faraday-http-cache', '~> 2.0'
gem 'faraday_middleware', '~> 0.13'
gem 'flipper'
gem 'flipper-active_record'
gem 'flipper-ui'
gem 'gelf'
gem 'graphiql-rails'
gem 'graphql'
gem 'honeybadger', '~> 4.5'
gem 'httparty'
gem 'jquery-rails', '~> 4.3'
gem 'json-schema', '~> 2.8'
gem 'librato-metrics', '~> 2.1.2'
gem 'logstasher', '~> 1.3'
gem 'mime-types'
gem 'oauth2'
gem 'omniauth', '~> 1.9'
gem 'omniauth-facebook', '~> 5.0'
gem 'omniauth-google-oauth2'
gem 'p3p', '~> 2.0'
gem 'panoptes-client'
gem 'pg', '~> 0.21'
gem 'pg_search'
gem 'puma', '~> 4.3.5'
gem 'pundit', '~> 2.1.0'
gem 'rack-cors', '~> 1.0', require: 'rack/cors'
if next?
  gem 'rails', '~> 5.0.0'
else
  gem 'rails', '~> 4.2.11' # rubocop:disable Bundler/DuplicatedGem
end
gem 'ranked-model', '~> 0.4.1'
gem 'restpack_serializer', git: 'https://github.com/zooniverse/restpack_serializer.git', branch: 'panoptes-api-version', ref: 'cef0969cef'
gem 'schema_plus_pg_indexes', '~> 0.1'
gem 'scientist', '~> 1.4.0'
gem 'sdoc', '~> 1.0.0', group: :doc
gem 'sidekiq', '~> 5.2.5'
gem 'sidekiq-congestion', '~> 0.1.0'
gem 'sidekiq-unique-jobs'
gem 'sidetiq', '~> 0.7'
gem 'standby'
gem 'stringex', '~> 2.8'
gem 'strong_migrations'
gem 'therubyracer', '~> 0.12'
gem 'uglifier', '~> 4.1'
gem 'versionist', '~> 2.0'
gem 'zoo_stream', '~> 1.0.1'

group :production, :staging do
  gem 'newrelic_rpm'
end

group :development, :test do
  gem 'factory_bot_rails'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'pry-stack_explorer'
  gem 'rubocop', '~> 0.83.0'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'spring'
  gem 'sprockets', '~>3.7'
  gem 'ten_years_rails'
end

group :test do
  gem 'database_cleaner', '~> 1.7.0'
  gem 'guard-rspec', require: false
  gem 'hashdiff'
  gem 'mock_redis'
  gem 'rails-controller-testing' if next?
  gem 'rspec'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'spring-commands-rspec'
end
