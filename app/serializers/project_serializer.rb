require "tasks_visitors/inject_strings"

class ProjectSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include MediaLinksSerializer
  include ContentSerializer

  EAGER_LOADS = [
    #  :project_contents,
    #  :workflows,
    #  :subject_sets,
     :pages,
     :attached_images,
     :avatar,
     :background,
     :tags
   ].freeze
  PRELOADS = [
    :project_roles,
    [ owner: { identity_membership: :user } ],
    :workflows,
    :subject_sets
  ].freeze
  ONLY_PRELOADS = [
    :project_roles,
    [ owner: { identity_membership: :user } ],
    :workflows,
    :subject_sets,
    :pages,
    :attached_images,
    :avatar,
    :background,
    :tags
  ].freeze

  attributes :id, :display_name, :classifications_count,
    :subjects_count, :created_at, :updated_at, :available_languages,
    :title, :description, :introduction, :private, :retired_subjects_count,
    :configuration, :live, :urls, :migrated, :classifiers_count, :slug, :redirect,
    :beta_requested, :beta_approved, :launch_requested, :launch_approved, :launch_date,
    :href, :workflow_description, :primary_language, :tags, :experimental_tools,
    :completeness, :activity, :state, :researcher_quote

  optional :avatar_src
  can_include :workflows, :subject_sets, :owners, :project_contents,
    :project_roles, :pages, :organization
  media_include :avatar, :background, :attached_images,
    classifications_export: { include: false},
    subjects_export: { include: false },
    aggregations_export: { include: false }
  can_filter_by :display_name, :slug, :beta_requested, :beta_approved,
    :launch_requested, :launch_approved, :private, :state, :live
  can_sort_by :launch_date, :activity, :completeness, :classifiers_count,
    :updated_at, :display_name

  def self.page(params = {}, scope = nil, context = {})
    if params.key?("state")
      if Project.states.include?(params["state"])
        params["state"] = Project.states[params["state"]]
      elsif params["state"] == "live"
        params["live"] = true
        params.delete("state")
        scope = scope.where(state: nil)
      end
    end

    experiment_name = "eager_load_projects"
    CodeExperiment.run(experiment_name) do |e|
      # e.run_if { Panoptes.flipper[experiment_name].enabled? }
    # e.use { super(params, scope, context) }
# #TODO: make this eager load work as it speeds up the app
    e.use { super(params, scope.eager_load(*EAGER_LOADS).preload(*PRELOADS), context) }
    e.try { super(params, scope.preload(*ONLY_PRELOADS), context) }
      # e.try { super(params, scope.preload(*PRELOADS), context) }
      # skip the mismatch reporting...we just want perf metrics
      e.ignore { true }
    end
  end

  def self.links
    links = super
    links["projects.pages"] = {
                               href: "/projects/{projects.id}/pages",
                               type: "project_pages"
                              }
    links
  end

  def add_links(model, data)
    if @context[:cards]
      data.merge!(links: {})
    else
      super(model, data)
    end
  end

  def title
    content[:title]
  end

  def description
    content[:description]
  end

  def workflow_description
    content[:workflow_description]
  end

  def introduction
    content[:introduction]
  end

  def researcher_quote
    content[:researcher_quote]
  end

  def urls
    if content
      urls = @model.urls.dup
      TasksVisitors::InjectStrings.new(content[:url_labels]).visit(urls)
      urls
    else
      []
    end
  end

  def tags
    @model.tags.map(&:name)
  end

  def avatar_src
    if avatar = @model.avatar
      avatar.external_link ? avatar.external_link : avatar.src
    else
      ""
    end
  end

  def fields
    %i(title description workflow_description introduction url_labels)
  end
end
