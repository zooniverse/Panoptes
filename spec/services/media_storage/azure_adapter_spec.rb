# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MediaStorage::AzureAdapter do
  let(:storage_account_name) { 'tiny-watermelons' }
  let(:public_container) { 'magic-container' }
  let(:private_container) { 'secret-magic-container' }
  let(:opts) do
    {
      url_prefix: 'https://test-uploads.zooniverse.org/container_name',
      azure_storage_account: storage_account_name,
      azure_storage_access_key: 'fake',
      azure_storage_container_public: public_container,
      azure_storage_container_private: private_container
    }
  end
  let(:adapter) { described_class.new(opts) }
  let(:uri_regex) { /\A#{URI::DEFAULT_PARSER.make_regexp}\z/ }
  let(:uuid_v4_regex) { /[a-f0-9]{8}\-[a-f0-9]{4}\-4[a-f0-9]{3}\-(8|9|a|b)[a-f0-9]{3}\-[a-f0-9]{12}/ }

  let(:signer) { instance_double('Azure::Storage::Common::Core::Auth::SharedAccessSignature') }
  let(:blob_client) { instance_double('Azure::Storage::Blob::BlobService') }

  before do
    allow(Azure::Storage::Common::Core::Auth::SharedAccessSignature).to receive(:new) { signer }
    allow(Azure::Storage::Blob::BlobService).to receive(:create) { blob_client }
  end

  context 'when opts are passed to the initializer' do
    it 'uses default expiration values when no expiration values are passed' do
      default = MediaStorage::AzureAdapter::DEFAULT_EXPIRES_IN
      expect(adapter.get_expiration).to eq(default)
      expect(adapter.put_expiration).to eq(default)
    end

    it 'creates the blob storage client using passed in options' do
      adapter
      expect(Azure::Storage::Blob::BlobService)
        .to have_received(:create)
        .with(
          storage_account_name: opts[:azure_storage_account],
          storage_access_key: opts[:azure_storage_access_key]
        )
    end

    it 'initializes the signer using passed in options' do
      adapter
      expect(Azure::Storage::Common::Core::Auth::SharedAccessSignature)
        .to have_received(:new)
        .with(opts[:azure_storage_account], opts[:azure_storage_access_key])
    end
  end

  describe '#stored_path' do
    subject do
      adapter.stored_path('image/jpeg', 'subject_location')
    end

    it { is_expected.to be_a(String) }
    it { is_expected.to match(/subject_location/) }
    it { is_expected.to match(/\.jpeg/) }
    it { is_expected.to match(uuid_v4_regex) }

    context 'with additional path prefixes' do
      subject { adapter.stored_path('image/jpeg', 'subject_location', 'extra', 'prefixes') }

      it { is_expected.to match(%r{extra\/prefixes}) }
    end

    context 'with an application/x-gzip content-type' do
      subject { adapter.stored_path('application/x-gzip', 'subject_location') }

      it { is_expected.to match(/\.tar\.gz\z/) }
    end
  end

  describe '#get_path' do
    before do
      allow(signer).to receive(:signed_uri)
      allow(blob_client)
        .to receive(:generate_uri)
        .and_return('https://tiny-watermelons.microsoftland.com/secret-magic-container/subject_locations/name.jpg')
      allow(adapter).to receive(:get_expiry_time).and_return('time-isnt-real')
    end

    context 'when medium is private' do
      let(:upload_options) { { private: true, get_expires: 10 } }

      before do
        adapter.get_path('subject_locations/name.jpg', upload_options)
      end

      it 'passes the expected params to the signer' do
        expect(signer)
          .to have_received(:signed_uri)
          .with(
            'https://tiny-watermelons.microsoftland.com/secret-magic-container/subject_locations/name.jpg',
            false,
            service: 'b',
            permissions: 'r',
            expiry: 'time-isnt-real'
          )
      end

      it 'passes the expected params to the blob client' do
        expect(blob_client).to have_received(:generate_uri).with('secret-magic-container/subject_locations/name.jpg')
      end

      it 'uses passed in option for generating expiry time' do
        expect(adapter).to have_received(:get_expiry_time).with(10)
      end
    end

    context 'when medium is public' do
      it 'uses the StoredPath.media_url method' do
        allow(MediaStorage::StoredPath).to receive(:media_url)
        src = 'subject_locations/name.jpg'
        adapter.get_path(src)
        expect(MediaStorage::StoredPath).to have_received(:media_url).with(opts[:url_prefix], src)
      end

      it 'returns the path as a https link' do
        expected_url = 'https://test-uploads.zooniverse.org/container_name/subject_locations/name.jpg'
        expect(adapter.get_path('subject_locations/name.jpg')).to eq(expected_url)
      end
    end
  end

  describe '#put_path' do
    let(:upload_options) { { content_type: 'image/jpg' } }

    before do
      allow(signer).to receive(:signed_uri)
      allow(blob_client)
        .to receive(:generate_uri)
        .with('magic-container/subject_locations/name.jpg')
        .and_return('https://tiny-watermelons.microsoftland.com/magic-container/subject_locations/name.jpg')
      allow(blob_client)
        .to receive(:generate_uri)
        .with('secret-magic-container/subject_locations/name.jpg')
        .and_return('https://tiny-watermelons.microsoftland.com/secret-magic-container/subject_locations/name.jpg')
      allow(adapter).to receive(:get_expiry_time).and_return('time-isnt-real')
    end

    context 'when required options are set' do
      before do
        adapter.put_path('subject_locations/name.jpg', upload_options)
      end

      it 'passes the expected params to the signer' do
        expect(signer)
          .to have_received(:signed_uri)
          .with(
            'https://tiny-watermelons.microsoftland.com/magic-container/subject_locations/name.jpg',
            false,
            service: 'b',
            permissions: 'cw',
            expiry: 'time-isnt-real',
            content_type: 'image/jpg'
          )
      end

      it 'passes the expected params to the blob client' do
        expect(blob_client).to have_received(:generate_uri).with('magic-container/subject_locations/name.jpg')
      end
    end

    context 'when put_expires option is set' do
      it 'uses passed in option for generating expiry time' do
        allow(adapter).to receive(:get_expiry_time)
        upload_options[:put_expires] = 10

        adapter.put_path('subject_locations/name.jpg', upload_options)
        expect(adapter).to have_received(:get_expiry_time).with(10)
      end
    end

    context 'when upload is private' do
      it 'uploads to the private container' do
        upload_options[:private] = true
        adapter.put_path('subject_locations/name.jpg', upload_options)

        expect(signer)
          .to have_received(:signed_uri)
          .with(
            'https://tiny-watermelons.microsoftland.com/secret-magic-container/subject_locations/name.jpg',
            false,
            service: 'b',
            permissions: 'cw',
            expiry: 'time-isnt-real',
            content_type: 'image/jpg'
          )
      end
    end
  end

  describe '#put_file' do
    let(:file) { instance_double('File') }
    let(:method_call_options) { { content_type: 'text/plain' } }

    before do
      allow(file).to receive(:close)
      allow(File).to receive(:open) { file }

      allow(blob_client).to receive(:create_block_blob)
    end

    it 'calls the create_block_blob method with correct arguments' do
      adapter.put_file('storage_path.txt', 'path_to_file.txt', method_call_options)
      expect(blob_client).to have_received(:create_block_blob).with(public_container, 'storage_path.txt', file, method_call_options)
    end

    it 'passes the private container to the blob client when the file is private' do
      method_call_options[:private] = true
      adapter.put_file('storage_path.txt', 'path_to_file.txt', method_call_options)
      expect(blob_client).to have_received(:create_block_blob).with(private_container, 'storage_path.txt', file, { content_type: 'text/plain' })
    end

    it 'sets content encoding to gzip if compressed option is set' do
      method_call_options[:compressed] = true
      adapter.put_file('storage_path.txt', 'path_to_file.txt', method_call_options)
      expect(blob_client)
        .to have_received(:create_block_blob)
        .with(public_container, 'storage_path.txt', file, { content_type: 'text/plain', content_encoding: 'gzip' })
    end

    it 'passes content disposition to the blob client when option is set' do
      method_call_options[:content_disposition] = 'attachment'

      adapter.put_file('storage_path.txt', 'path_to_file.txt', method_call_options)
      expect(blob_client).to have_received(:create_block_blob).with(public_container, 'storage_path.txt', file, method_call_options)
    end
  end

  describe '#delete_file' do
    it 'calls the delete_blob method with correct arguments' do
      allow(blob_client).to receive(:delete_blob)

      adapter.delete_file('path_to_file.txt')
      expect(blob_client).to have_received(:delete_blob).with(public_container, 'path_to_file.txt')
    end
  end

  describe '#safe_for_private_upload?' do
    it 'returns false if the container is not private' do
      az_container = instance_double('Azure::Storage::Blob::Container::Container', public_access_level: 'blob')
      allow(adapter.client).to receive(:get_container_acl).with('private').and_return([az_container, []])
      expect(adapter.safe_for_private_upload?).to eq(false)
    end

    it 'returns true if container is private' do
      az_container = instance_double('Azure::Storage::Blob::Container::Container', public_access_level: nil)
      allow(adapter.client).to receive(:get_container_acl).with('private').and_return([az_container, []])
      expect(adapter.safe_for_private_upload?).to eq(true)
    end
  end
end
