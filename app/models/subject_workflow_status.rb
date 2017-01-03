class SubjectWorkflowStatus < ActiveRecord::Base
  self.table_name = 'subject_workflow_counts'

  include RoleControl::ParentalControlled

  belongs_to :subject
  belongs_to :workflow

  enum retirement_reason:
    [ :classification_count, :flagged, :nothing_here, :consensus, :other ]

  scope :retired, -> { where.not(retired_at: nil) }

  validates :subject, presence: true, uniqueness: {scope: :workflow_id}
  validates :workflow, presence: true
  validate :subject_belongs_to_workflow, on: :create

  delegate :set_member_subjects, to: :subject
  delegate :project, to: :workflow

  can_through_parent :workflow, :show, :index

  def self.by_set(subject_set_id)
    joins(:subject => :set_member_subjects)
      .where(set_member_subjects: {subject_set_id: subject_set_id})
  end

  def self.by_subject(subject_id)
    where(subject_id: subject_id)
  end

  def self.by_subject_workflow(subject_id, workflow_id)
    where(subject_id: subject_id, workflow_id: workflow_id).first
  end

  def retire?
    !retired? && workflow.retirement_scheme.retire?(self)
  end

  def retire!(reason=nil)
    unless retired?
      update!(retirement_reason: reason, retired_at: Time.zone.now)
    end
  end

  def retired?
    retired_at.present?
  end

  def set_member_subject_ids
    set_member_subjects.pluck(:id)
  end

  private

  def subject_belongs_to_workflow
    return unless subject_id && workflow_id

    unless SetMemberSubject.by_subject_workflow(subject_id, workflow_id).exists?
      errors.add(:subject, "must be linked to the workflow")
    end
  end
end
