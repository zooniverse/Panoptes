class ProjectSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include MediaLinksSerializer
  include BlankTypeSerializer

  attributes :id, :display_name, :classifications_count,
    :subjects_count, :created_at, :updated_at, :available_languages,
    :title, :description, :guide, :team_members, :science_case,
    :introduction, :private, :faq, :result, :education_content,
    :retired_subjects_count, :configuration, :live,
    :urls, :migrated, :classifiers_count, :slug, :redirect,
    :beta_requested, :beta_approved, :launch_requested, :launch_approved

  can_include :workflows, :subject_sets, :owners, :project_contents,
    :project_roles
  can_filter_by :display_name, :slug, :beta_requested, :beta_approved, :launch_requested, :launch_approved
  media_include :avatar, :background, :attached_images, classifications_export: { include: false}

  def title
    content[:title]
  end

  def description
    content[:description]
  end

  def guide
    content[:guide]
  end

  def team_members
    content[:team_members]
  end

  def science_case
    content[:science_case]
  end

  def introduction
    content[:introduction]
  end

  def education_content
    content[:education_content]
  end

  def faq
    content[:faq]
  end

  def result
    content[:result]
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

  def content
    @content ||= _content
  end

  def _content
    content = @model.content_for(@context[:languages])
    content = @context[:fields].map{ |k| Hash[k, content.send(k)] }.reduce(&:merge)
    content.default_proc = proc { |hash, key| "" }
    content
  end
end
