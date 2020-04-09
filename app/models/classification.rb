class Classification < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  belongs_to :workflow
  belongs_to :user_group

  has_one :export_row, class_name: "ClassificationExportRow"

  has_many :recents, -> { where(mark_remove: false) }, inverse_of: :classification

  has_and_belongs_to_many :subjects,
    join_table: :classification_subjects,
    validate: false

  enum expert_classifier: [:expert, :owner]

  validates_presence_of :subjects, :project,
    :workflow, :annotations, :user_ip, :workflow_version

  validates :user, presence: {message: "Only logged in users can store incomplete classifications"}, if: :incomplete?
  validate :metadata, :validate_metadata
  validate :validate_gold_standard

  scope :incomplete, -> { where("completed IS FALSE") }
  scope :created_by, -> (user) { where(user_id: user.id) }
  scope :complete, -> { where(completed: true) }
  scope :gold_standard, -> { where("gold_standard IS TRUE") }
  scope :after_id, lambda { |last_id|
    where("classifications.id > ?", last_id)
    .order("classifications.id")
  }

  before_destroy :mark_recents_for_removal

  def self.joins_classification_subjects
    joins("INNER JOIN classification_subjects ON classifications.id = classification_subjects.classification_id")
  end

  def self.incomplete_for_user(user)
    incomplete.merge(created_by(user))
  end

  def created_and_incomplete?(actor)
    creator?(actor) && incomplete?
  end

  def creator?(actor)
    user == actor.user
  end

  def complete?
    completed
  end

  def incomplete?
    !completed
  end

  def anonymous?
    !user
  end

  def seen_before?
    if seen_before = metadata[:seen_before]
      !!"#{seen_before}".match(/^true$/i)
    else
      false
    end
  end

  def metadata
    read_attribute(:metadata).with_indifferent_access
  end

  private

  def validate_metadata
    validate_seen_before
    required_metadata_present
  end

  def required_metadata_present
    %i(started_at finished_at user_language user_agent).each do |key|
      unless metadata.has_key? key
        errors.add(:metadata, "must have #{key} metadata")
      end
    end
  end

  def validate_seen_before
    if metadata.has_key?(:seen_before) && !seen_before?
      errors.add(:metadata, "seen_before attribute can only be set to 'true'")
    end
  end

  def validate_gold_standard
    ClassificationValidator.new(self).validate_gold_standard
  end

  # recents can be a large table, thus finding all for removal
  # in the destroy transaction can be longer than the statement timeout
  # instead mark them for removal and allow them to be cleaned up later
  # i.e. mark and sweep
  def mark_recents_for_removal
    recents.update_all(mark_remove: true)
  end
end
