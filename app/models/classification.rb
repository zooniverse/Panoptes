class Classification < ActiveRecord::Base
  include BelongsToMany
  include Counter::Cache

  belongs_to :project
  belongs_to :user
  belongs_to :workflow
  belongs_to :user_group
  belongs_to_many :subjects

  has_many :recents, dependent: :destroy

  enum expert_classifier: [:expert, :owner]

  validates_presence_of :subject_ids, :project,
    :workflow, :annotations, :user_ip, :workflow_version

  validates :user, presence: {message: "Only logged in users can store incomplete classifications"}, if: :incomplete?
  validate :metadata, :validate_metadata
  validate :validate_gold_standard

  scope :incomplete, -> { where(completed: false) }
  scope :created_by, -> (user) { where(user: user) }
  scope :complete, -> { where(completed: true) }

  %w(project user workflow user_group).each do |model|
    counter_cache_on column: :classifications_count, relation: model.to_sym,
      method: :classification_count, relation_class_name: model.capitalize
  end

  def self.scope_for(action, user, opts={})
    return all if user.is_admin?
    case action
    when :show, :index
      query = joins(:project).merge(Project.scope_for(:update, user))
              .merge(complete)
              .union_all(incomplete_for_user(user))
      query
    when :update, :destroy
      incomplete_for_user(user)
    else
      none
    end
  end

  def self.incomplete_for_user(user)
    incomplete.merge(created_by(user.user))
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
end
