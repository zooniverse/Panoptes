class SubjectSetImport < ActiveRecord::Base
  include RoleControl::ParentalControlled

  belongs_to :subject_set
  belongs_to :user

  can_through_parent :subject_set

  def import!
    processor = SubjectSetImport::Processor.new(subject_set, user)

    UrlDownloader.stream(source_url) do |io|
      csv_import = SubjectSetImport::CsvImport.new(io)
      csv_import.each do |uuid, attributes|
        processor.import(uuid, attributes)
      end
    end
  end

end
