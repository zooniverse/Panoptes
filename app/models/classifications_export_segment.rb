class ClassificationsExportSegment < ActiveRecord::Base
  belongs_to :project
  belongs_to :workflow
  belongs_to :first_classification, class_name: 'Classification', foreign_key: 'first_classification_id'
  belongs_to :last_classification,  class_name: 'Classification', foreign_key: 'last_classification_id'
  belongs_to :requester, class_name: 'User', foreign_key: 'requester_id'

  validates :first_classification_id, presence: true
  validates :last_classification_id, presence: true

  has_one :medium, as: :linked

  def classifications_in_segment
    complete_classifications
      .where("classifications.id >= ? AND classifications.id <= ?", first_classification_id, last_classification_id)
      .joins(:workflow)
      .includes(:user, workflow: [:workflow_contents])
  end

  def next_segment
    segment = self.class.new(project_id: project_id, workflow_id: workflow_id, requester: requester)
    segment.set_first_last_classifications(last_classification_id)
    segment
  end

  def set_first_last_classifications(after)
    scope = complete_classifications
    scope = scope.where("id > ?", after) if after.present?

    res = scope.select("min(id), max(id)").limit(1).load[0]

    self.first_classification_id = res.min
    self.last_classification_id = res.max
  end

  private

  def complete_classifications
    workflow.classifications.complete
  end
end
