require 'csv'

class EmailsProjectsExportWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(project_id)
    project = Project.find(project_id)
    direct_to_object_storage = CsvDumps::DirectToObjectStorage.new(
      export_type(project),
      ENV.fetch('EMAIL_EXPORT_STORAGE_ADAPTER', 'aws')
    )
    formatter = Formatter::Csv::UserEmail.new
    scope = CsvDumps::ProjectEmailList.new(project_id)
    processor = CsvDumps::DumpProcessor.new(formatter, scope, direct_to_object_storage)
    processor.execute
  rescue ActiveRecord::RecordNotFound
  end

  private

  def export_type(project)
    project.slug
  end
end
