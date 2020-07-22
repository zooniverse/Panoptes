# frozen_string_literal: true

module Panoptes
  module StorageAdapter
    def self.configuration
      @configuration ||=
        {
          adapter: ENV.fetch('STORAGE_ADAPTER', 'test'),
          bucket: ENV['STORAGE_BUCKET'],
          prefix: ENV['STORAGE_PREFIX'],
          storage_account_name: ENV.fetch('AZURE_STORAGE_ACCOUNT', 'panoptes'),
          storage_access_key: ENV['STORAGE_ACCESS_KEY'],
          storage_container: ENV.fetch('STORAGE_CONTAINER', 'test')
        }
    end
  end
end

MediaStorage.adapter(
  Panoptes::StorageAdapter.configuration[:adapter],
  **Panoptes::StorageAdapter.configuration.except(:adapter)
)
