class Subject < ActiveRecord::Base
  include Activatable
  include OrderedLocations

  belongs_to :project
  belongs_to :uploader, class_name: "User", foreign_key: "upload_user_id"
  has_many :collections_subjects, dependent: :restrict_with_exception
  has_many :collections, through: :collections_subjects
  has_many :subject_sets, through: :set_member_subjects
  has_many :set_member_subjects, dependent: :destroy
  has_many :workflows, through: :set_member_subjects
  has_many :subject_workflow_statuses, dependent: :restrict_with_exception
  has_many :locations,
    -> { where(type: 'subject_location') },
    class_name: "Medium",
    as: :linked
  has_many :recents
  has_many :aggregations, dependent: :destroy
  has_many :tutorial_workflows,
    class_name: 'Workflow',
    foreign_key: 'tutorial_subject_id',
    dependent: :restrict_with_exception

  # Used by HttpCacheable
  scope :private_scope, -> { where(project_id: Project.private_scope) }

  validates_presence_of :project, :uploader

  NONSTANDARD_MIMETYPES = {
    "audio/mp3" => "audio/mpeg",
    "audio/x-wav" => "audio/mpeg"
  }.freeze

  def self.location_attributes_from_params(locations)
    (locations || []).map.with_index do |loc, i|
      location_params = case loc
                        when String
                          { content_type: standardize_mimetype(loc) }
                        when Hash
                          {
                            content_type: standardize_mimetype(loc.keys.first),
                            external_link: true,
                            src: loc.values.first
                          }
                        end
      location_params[:metadata] = { index: i }
      location_params
    end
  end

  def self.standardize_mimetype(mimetype)
    NONSTANDARD_MIMETYPES[mimetype] || mimetype
  end

  def migrated_subject?
    !!migrated
  end

  def retired_workflows
    SubjectWorkflowStatus
      .retired
      .where(subject: self)
      .includes(:workflow)
      .map(&:workflow)
  end

  def retired_for_workflow?(workflow)
    if workflow&.persisted?
      SubjectWorkflowStatus.retired.by_subject_workflow(self.id, workflow.id).present?
    else
      false
    end
  end
end
