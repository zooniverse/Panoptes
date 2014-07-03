source 'https://rubygems.org'

gem 'rails', '4.1.1'
gem 'sass-rails', '~> 4.0.3'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0',          group: :doc
gem 'doorkeeper', github: 'edpaget/doorkeeper'
gem 'devise'
gem 'versionist'
gem 'rack-cors', require: 'rack/cors'
gem 'restpack_serializer'
gem 'json-patch', '~> 1.0.0'
gem 'rolify'
gem 'pundit'
gem 'paper_trail'
gem 'cellect-client', '~> 0.0.6'

platforms :jruby do
  gem 'activerecord-jdbcpostgresql-adapter', github: 'jruby/activerecord-jdbc-adapter'
  gem 'therubyrhino'
end

platforms :ruby do
  gem 'therubyracer'
  gem 'pg'
end

group :development do
  gem 'spring'
  gem 'mysql2', platforms: :ruby
  gem 'activerecord-jdbcmysql-adapter', platforms: :jruby
end

group :development, :test do
  gem 'database_cleaner', '~> 1.2.0'
  gem 'rspec', '~> 3.0.0'
  gem 'rspec-rails', '~> 3.0.0'
  gem 'guard-rspec', '~> 4.2.9', require: false
  gem 'factory_girl_rails', '~> 4.4.1'
  gem 'spring-commands-rspec', '~> 1.0.2'
  gem 'pry-rails', '~> 0.3.2'
end
