# frozen_string_literal: true

require 'spec_helper'

describe CsvDumps::DirectToObjectStorage do
  let(:direct_to_object_store) { described_class.new('full', 'test') }
  let(:adapter) { direct_to_object_store.storage_adapter }
  let(:object_store_file_name) { 'full_email_list' }
  let(:object_store_path) { "email_exports/#{object_store_file_name}.csv" }
  let(:put_file_opts) do
    {
      private: true,
      compressed: true,
      content_disposition: "attachment; filename=\"#{object_store_file_name}.csv\""
    }
  end
  let(:file_path) { '/tmp/foobar' }

  let(:adapter_opts) do
    {
      # s3 adapter specific
      bucket: 'zooniverse-exports',
      prefix: "#{Rails.env}/",
      # azure adapter specific
      azure_storage_account: 'zooniverse-exports',
      azure_storage_access_key: 'fake-key',
      azure_storage_container_public: 'private',
      azure_storage_container_private: 'private'
    }
  end
  let(:test_adapter) { MediaStorage::TestAdapter.new(adapter_opts) }

  before do
    ENV['EMAIL_EXPORT_AZURE_STORAGE_ACCESS_KEY'] = 'fake-key'
  end

  it 'wires up the aws adapter correctly' do
    allow(MediaStorage).to receive(:load_adapter)
    described_class.new('full', 'aws').storage_adapter
    expect(MediaStorage).to have_received(:load_adapter).with('aws', adapter_opts)
  end

  it 'wires up the azure adapter correctly' do
    allow(MediaStorage).to receive(:load_adapter)
    described_class.new('full', 'azure').storage_adapter
    expect(MediaStorage).to have_received(:load_adapter).with('azure', adapter_opts)
  end

  context 'with the test adapter double' do
    before do
      allow(MediaStorage).to receive(:load_adapter).and_return(test_adapter)
    end

    it 'wires up the test adapter correctly' do
      adapter
      expect(MediaStorage).to have_received(:load_adapter).with('test', adapter_opts)
    end

    describe 'uploading using put_file' do
      it 'correctly determines the object storage location path' do
        allow(adapter).to receive(:stored_path).and_call_original
        direct_to_object_store.put_file(file_path)
        expect(adapter).to have_received(:stored_path).with('text/csv', 'email_exports')
      end

      it 'uploads the file to the the correct object store location' do
        allow(adapter).to receive(:put_file)
        direct_to_object_store.put_file(file_path)
        expect(adapter).to have_received(:put_file).with(object_store_path, file_path, put_file_opts)
      end
    end

    describe 'safe_for_private_upload?' do
      it "raises an error if it's not safe for upload" do
        allow(adapter).to receive(:safe_for_private_upload?).and_return(false)
        expect {
          direct_to_object_store.put_file(file_path)
        }.to raise_error(CsvDumps::DirectToObjectStorage::InsecureUploadDestination, 'the object store upload destination is insecure')
      end

      it 'does not raise when the it is safe to upload' do
        expect { direct_to_object_store.put_file(file_path) }.not_to raise_error
      end
    end
  end
end
