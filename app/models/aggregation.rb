class Aggregation < ActiveRecord::Base
  include RoleControl::ParentalControlled

  belongs_to :workflow
  belongs_to :subject

  has_paper_trail only: [:aggregation]

  can_through_parent :workflow, :update, :destroy, :update_links,
                     :destroy_links, :versions, :version

  validates_presence_of :workflow, :subject, :aggregation
  validates_uniqueness_of :subject_id, scope: :workflow_id
  validate :aggregation, :workflow_version_present

  def self.scope_for(action, user, opts={})
    if (action == :show || action == :index) && !user.is_admin?
      updatable = Workflow.scope_for(:update, user, opts.merge(skip_eager_load: true))
      controlled_scope = joins(:workflow).merge(updatable)
      joins(:workflow)
        .where("workflows.aggregation ->> 'public' = 'true'")
        .union(controlled_scope)
    else
      super
    end
  end

  private

  def workflow_version_present
    wv_key = :workflow_version
    if aggregation && !aggregation.symbolize_keys.has_key?(wv_key)
      errors.add(:aggregation, "must have #{wv_key} metadata")
    end
  end
end
