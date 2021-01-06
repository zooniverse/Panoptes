module CsvDumps
  class DumpProcessor
    include ActiveSupport::Callbacks

    attr_reader :csv_dump, :formatter, :scope, :medium

    define_callbacks :dump
    define_callbacks :upload
    define_callbacks :cleanup

    def initialize(formatter, scope, medium, csv_dump = CsvDump.new)
      @formatter = formatter
      @scope = scope
      @medium = medium
      @csv_dump = csv_dump
    end

    def execute
      perform_dump
      upload_dump
    ensure
      cleanup_dump
    end

    def perform_dump
      csv_dump << formatter.headers if formatter.headers

      scope.each do |model|
        formatter.to_rows(model).each do |row|
          csv_dump << row
        end
      end
    end

    def upload_dump
      gzip_file_path = csv_dump.gzip!
      write_to_object_store(gzip_file_path)
      set_ready_state
    end

    def cleanup_dump
      csv_dump.cleanup!
    end

    private

    def set_ready_state
      medium.metadata["state"] = 'ready'
      medium.save!
    end

    def write_to_object_store(gzip_file_path)
      medium.put_file(gzip_file_path, compressed: true)
    end
  end
end
