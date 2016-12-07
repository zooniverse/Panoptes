class Project < ActiveRecord::Base
  include RoleControl::Owned
  include RoleControl::Controlled
  include Activatable
  include Linkable
  include Translatable
  include PreferencesLink
  include ExtendedCacheKey
  include PgSearch
  include RankedModel
  include SluggedName

  EXPERT_ROLES = [:owner, :expert].freeze

  has_many :tutorials
  has_many :field_guides, dependent: :destroy
  belongs_to :organization
  # uses the activated_state enum on the workflow
  has_many :workflows, -> { active }, dependent: :restrict_with_exception
  # uses the active attribute on the workflow
  has_many :active_workflows, -> { where(active: true) }, class_name: "Workflow"
  has_many :subject_sets, dependent: :destroy
  has_many :live_subject_sets, through: :workflows, source: 'subject_sets'
  has_many :classifications, dependent: :restrict_with_exception
  has_many :subjects, dependent: :restrict_with_exception
  has_many :acls, class_name: "AccessControlList", as: :resource, dependent: :destroy
  has_many :project_roles, -> { where.not(roles: []) }, class_name: "AccessControlList", as: :resource
  has_one :avatar, -> { where(type: "project_avatar") }, class_name: "Medium", as: :linked
  has_one :background, -> { where(type: "project_background") }, class_name: "Medium",
    as: :linked
  has_one :classifications_export, -> { where(type: "project_classifications_export").order(created_at: :desc) },
    class_name: "Medium", as: :linked
  has_one :aggregations_export, -> { where(type: "project_aggregations_export").order(created_at: :desc) },
    class_name: "Medium", as: :linked
  has_one :subjects_export, -> { where(type: "project_subjects_export").order(created_at: :desc) },
    class_name: "Medium", as: :linked
  has_one :workflows_export, -> { where(type: "project_workflows_export").order(created_at: :desc) },
    class_name: "Medium", as: :linked
  has_one :workflow_contents_export, -> { where(type: "project_workflow_contents_export").order(created_at: :desc) },
    class_name: "Medium", as: :linked
  has_many :attached_images, -> { where(type: "project_attached_image") }, class_name: "Medium",
    as: :linked
  has_many :pages, class_name: "ProjectPage", dependent: :destroy
  has_many :tagged_resources, as: :resource
  has_many :tags, through: :tagged_resources
  has_many :first_time_users, class_name: "User", foreign_key: 'project_id', inverse_of: :signup_project, dependent: :restrict_with_exception

  has_paper_trail only: [:private, :live, :beta_requested, :beta_approved, :launch_requested, :launch_approved]

  enum state: [:paused, :finished]

  cache_by_association :project_contents, :tags
  cache_by_resource_method :subjects_count, :retired_subjects_count, :finished?

  accepts_nested_attributes_for :project_contents

  validates_inclusion_of :private, :live, in: [true, false], message: "must be true or false"

  ## TODO: This potential has locking issues
  validates_with UniqueForOwnerValidator

  after_update :send_notifications

  scope :launched, -> { where("launch_approved IS TRUE") }

  can_by_role :destroy, :update, :update_links, :destroy_links, :create_classifications_export,
    :create_subjects_export, :create_aggregations_export, :create_workflows_export,
    :create_workflow_contents_export, :retire_subjects, roles: [ :owner, :collaborator ]

  can_by_role :show, :index, :versions, :version, public: true,
    roles: [ :owner, :collaborator, :tester, :translator, :scientist, :moderator ]

  can_by_role :translate, roles: [ :owner, :translator, :collaborator ]

  can_be_linked :subject_set, :scope_for, :update, :user
  can_be_linked :subject, :scope_for, :update, :user

  can_be_linked :workflow, :scope_for, :update, :user
  can_be_linked :access_control_list, :scope_for, :update, :user
  can_be_linked :user_group, :scope_for, :edit_project, :user

  preferences_model :user_project_preference

  pg_search_scope :search_display_name,
    against: :display_name,
    using: {
      tsearch: {
        dictionary: "english",
        tsvector_column: "tsv"
      },
      trigram: {}
    },
    :ranked_by => ":tsearch + (0.25 * :trigram)"

  ranks :launched_row_order
  ranks :beta_row_order

  def expert_classifier_level(classifier)
    expert_roles = project_roles.where(user_group: classifier.identity_group)
      .where
      .overlap(roles: EXPERT_ROLES)
    if roles = expert_roles.first.try(:roles)
      (EXPERT_ROLES & roles.map(&:to_sym)).first
    end
  end

  def expert_classifier?(classifier)
    !!expert_classifier_level(classifier)
  end

  def owners_and_collaborators
    User.joins(user_groups: :access_control_lists)
      .merge(acls.where.overlap(roles: %w(owner collaborator)))
      .select(:id)
  end

  def create_talk_admin(client)
    owners_and_collaborators.each do |user|
      client.roles.create(name: 'admin',
                          user_id: user.id,
                          section: "project-#{id}")
    end
  end

  def slugged_name
    "#{ owner.try(:login) || owner.try(:name) }/#{ display_name.gsub('/', '-') }"
  end

  def send_notifications
    if Panoptes.project_request.recipients
      request_type = if beta_requested_changed? && beta_requested
                       "beta"
                     elsif launch_requested_changed? && launch_requested
                       "launch"
                     end
      ProjectRequestEmailWorker.perform_async(request_type, id) if request_type
    end
  end

  def subjects_count
    @subject_count ||= live_subject_sets.sum :set_member_subjects_count
  end

  def retired_subjects_count
    @retired_subject_count ||= active_workflows.sum :retired_set_member_subjects_count
  end

  def finished?
    super ? super : active_workflows.all?(&:finished?)
  end

  def state
    if self[:state]
      super
    else
      live ? "live" : "development"
    end
  end
end
