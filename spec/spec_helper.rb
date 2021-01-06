# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
# ensure the email exports code paths use the test storage adapter
ENV['EMAIL_EXPORT_STORAGE_ADAPTER'] = 'test'
# ensure all Aws sdk interactions are stubbed and don't call aws cloud
require 'aws-sdk'
Aws.config[:stub_responses] = true
require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "sidekiq/testing"
require 'flipper/adapters/memory'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include Devise::TestHelpers, type: :controller
  config.include APIRequestHelpers, type: :controller
  config.include APIResponseHelpers, type: :controller
  config.include APIRequestHelpers, type: :request
  config.include APIResponseHelpers, type: :request
  config.include ValidUserRequestHelper, type: :request
  config.include SubjectSelectionHelpers
  config.include Flipper
  config.extend RSpec::Helpers::ActiveRecordMocks

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.use_transactional_fixtures = false
  config.example_status_persistence_file_path = "./spec/examples.txt"

  config.filter_run_excluding disabled: true

  Devise.mailer = Devise::Mailer

  # disable standby reads to deal with testing transaction isolation
  Standby.disabled = true

  # work around https://github.com/celluloid/celluloid/issues/696
  Celluloid.shutdown_timeout = 1

  MOCK_REDIS ||= MockRedis.new

  config.before(:suite) do
    DatabaseCleaner.clean_with(:deletion)

    SidekiqUniqueJobs.configure do |suj_config|
      suj_config.enabled = !Rails.env.test?
    end
  end

  config.before(:each) do |example|
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    ActionMailer::Base.deliveries.clear

    allow(Redis).to receive(:new).and_return(MOCK_REDIS)

    MOCK_REDIS.keys.each do |key|
      MOCK_REDIS.del(key)
    end

    # Clears out the jobs for tests using the fake testing
    Sidekiq::Worker.clear_all

    # Enable all Scientist experiments
    CodeExperiment.always_enabled = true
    CodeExperiment.raise_on_mismatches = true

    case example.metadata[:sidekiq]
    when :fake
      Sidekiq::Testing.fake!
    when :inline
      Sidekiq::Testing.inline!
    when :feature
      Sidekiq::Testing.inline!
    else
      Sidekiq::Testing.fake!
    end
  end

  config.before(:example, with_cache_store: true) do
    cache_store = ActiveSupport::Cache::MemoryStore.new(size: 2.megabytes)
    allow(Rails).to receive(:cache).and_return(cache_store)
  end

  config.after(:each) do |example|
    DatabaseCleaner.clean
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end
