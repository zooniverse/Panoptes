class OrganizationSerializer
  include Serialization::PanoptesRestpack
  include OwnerLinkSerializer
  include MediaLinksSerializer
  include CachedSerializer

  attributes :id, :display_name, :description, :introduction, :title, :href,
    :primary_language, :listed_at, :listed, :slug, :urls, :categories, :announcement
  optional :avatar_src
  media_include :avatar, :background, :attached_images
  can_filter_by :display_name, :slug, :listed
  can_include :organization_contents, :organization_roles, :projects, :owner, :pages
  preload :organization_contents, :projects, [ owner: { identity_membership: :user } ],
    :avatar, :background, :organization_roles, :pages, :attached_images

  def title
    content[:title]
  end

  def description
    content[:description]
  end

  def introduction
    content[:introduction]
  end

  def announcement
    content[:announcement]
  end

  def avatar_src
    if avatar = @model.avatar
      avatar.external_link ? avatar.external_link : avatar.src
    else
      ""
    end
  end

  def self.links
    links = super
    links["organizations.pages"] = {
                               href: "/organizations/{organizations.id}/pages",
                               type: "organization_pages"
                              }
    links
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
    return @content if @content
    content = @model.organization_contents.attributes.with_indifferent_access
    content.default = ""
    @content = content.slice(*Api::V1::OrganizationsController::CONTENT_FIELDS)
  end
end
