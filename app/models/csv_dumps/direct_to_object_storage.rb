# frozen_string_literal: true

module CsvDumps
  # Custom 'Medium' duck type class to interface directly to
  # a custom object storage location to securely host export files
  # s3: (bucket, paths)
  # Azure blob: (storage account, container, paths)
  class DirectToObjectStorage
    attr_reader :export_type, :adapter

    class InsecureUploadDestination < StandardError; end

    def initialize(export_type, adapter)
      @export_type = export_type
      @adapter = adapter
    end

    def metadata
      {}
    end

    def save!
      true
    end

    def put_file(gzip_file_path, compressed: true)
      safe_for_private_upload?

      storage_adapter.put_file(
        object_storage_emails_export_path,
        gzip_file_path,
        put_file_opts
      )
    end

    def storage_adapter
      return @storage_adapter if @storage_adapter

      storage_opts = {
        # s3 adapter specific
        bucket: ENV.fetch('EMAIL_EXPORT_S3_BUCKET', 'zooniverse-exports'),
        prefix: ENV.fetch('EMAIL_EXPORT_S3_PREFIX', "#{Rails.env}/"),
        # azure adapter specific
        azure_storage_account: ENV.fetch('EMAIL_EXPORT_AZURE_STORAGE_ACCOUNT', 'zooniverse-exports'),
        azure_storage_access_key: ENV['EMAIL_EXPORT_AZURE_STORAGE_ACCESS_KEY'],
        azure_storage_container_public: ENV.fetch('EMAIL_EXPORT_AZURE_STORAGE_CONTAINER_PRIVATE', 'private'), # ensure private containers only
        azure_storage_container_private: ENV.fetch('EMAIL_EXPORT_AZURE_STORAGE_CONTAINER_PRIVATE', 'private')
      }

      @storage_adapter = MediaStorage.send(:load_adapter, adapter, storage_opts)
    end

    private

    def put_file_opts
      {
        private: true,
        compressed: true,
        content_disposition: "attachment; filename=\"#{export_file_name}.csv\""
      }
    end

    def object_storage_emails_export_path(path='email_exports')
      storage_path = storage_adapter.stored_path('text/csv', path)
      prefix = File.dirname(storage_path)
      file_paths = File.basename(storage_path).split('.')
      file_paths.shift
      exts = file_paths.join('.')
      "#{prefix}/#{export_file_name}.#{exts}"
    end

    def export_file_name
      "#{export_type}_email_list"
    end

    def safe_for_private_upload?
      return if storage_adapter.safe_for_private_upload?

      raise InsecureUploadDestination, 'the object store upload destination is insecure'
    end
  end
end
