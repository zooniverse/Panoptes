# frozen_string_literal: true

module MediaStorage
  class AzureAdapter < AbstractAdapter
    attr_reader :url_prefix, :public_container, :private_container, :storage_account_name, :get_expiration, :put_expiration, :client, :signer

    DEFAULT_EXPIRES_IN = 3 # time in minutes, see get_expiry_time(expires_in)

    def initialize(opts={})
      @storage_account_name = opts[:azure_storage_account]
      @public_container = opts[:azure_storage_container_public]
      @private_container = opts[:azure_storage_container_private]
      @url_prefix = opts[:url_prefix]
      @get_expiration = opts.dig(:expiration, :get) || DEFAULT_EXPIRES_IN
      @put_expiration = opts.dig(:expiration, :put) || DEFAULT_EXPIRES_IN

      @client = Azure::Storage::Blob::BlobService.create(
        storage_account_name: opts[:azure_storage_account],
        storage_access_key: opts[:azure_storage_access_key]
      )
      @signer = Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(
        opts[:azure_storage_account],
        opts[:azure_storage_access_key]
      )
    end

    def stored_path(content_type, medium_type, *path_prefix)
      extension = get_extension(content_type)
      path = "#{medium_type}/"
      path += "#{path_prefix.join('/')}/" unless path_prefix.empty?
      path + "#{SecureRandom.uuid}.#{extension}"
    end

    def get_path(path, opts={})
      if opts[:private]
        azure_path = StoredPath.media_path(path)
        azure_container_path = File.join(private_container, azure_path)
        signer.signed_uri(
          client.generate_uri(azure_container_path),
          false,
          service: 'b', # blob
          permissions: 'r', # read
          expiry: get_expiry_time(opts[:get_expires] || get_expiration)
        ).to_s
      else
        StoredPath.media_url(url_prefix, path)
      end
    end

    def put_path(path, opts={})
      container = opts[:private] ? private_container : public_container

      signer.signed_uri(
        client.generate_uri("#{container}/#{path}"),
        false,
        service: 'b', # blob
        permissions: 'cw', # create write
        expiry: get_expiry_time(opts[:put_expires] || put_expiration),
        content_type: opts[:content_type]
      ).to_s
    end

    def put_file(path, file_path, opts={})
      container = opts[:private] ? private_container : public_container
      upload_options = { content_type: opts[:content_type] }
      upload_options[:content_encoding] = 'gzip' if opts[:compressed]
      upload_options[:content_disposition] = opts[:content_disposition] if opts[:content_disposition]

      file = File.open file_path, 'r'
      client.create_block_blob(container, path, file, upload_options)
    ensure
      file.close
    end

    def delete_file(path, opts={})
      container = opts[:private] ? private_container : public_container
      client.delete_blob(container, path)
    end

    def safe_for_private_upload?
      # https://www.rubydoc.info/gems/azure-storage-blob/1.1.0/Azure/Storage/Blob/Container#get_container_acl-instance_method
      container = client.get_container_acl('private')[0]
      # nil public_access_level attribute means no public access
      container.public_access_level.nil?
    end

    private

    # @param expires_in [int]: time increment in minutes
    def get_expiry_time(expires_in)
      Time.now.utc.advance(minutes: expires_in).iso8601 # required format is UTC time zone, ISO 8601
    end
  end
end
