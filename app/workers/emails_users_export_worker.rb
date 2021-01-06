require 'csv'

class EmailsUsersExportWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(export_type=:global)
    direct_to_object_store = CsvDumps::DirectToObjectStorage.new(
      export_type,
      ENV.fetch('EMAIL_EXPORT_STORAGE_ADAPTER', 'aws')
    )
    formatter = Formatter::Csv::UserEmail.new
    scope = CsvDumps::FullEmailList.new(export_type)
    processor = CsvDumps::DumpProcessor.new(formatter, scope, direct_to_object_store)
    processor.execute
  end
end
