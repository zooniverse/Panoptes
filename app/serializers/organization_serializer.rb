class OrganizationSerializer
  include RestPack::Serializer
  include ContentSerializer
  include MediaLinksSerializer

  attributes :id, :name, :display_name, :description, :introduction, :title, :href
  optional :avatar_src
  media_include :avatar, :background
  can_include :organization_contents, :projects

  def title
    content[:title]
  end

  def description
    content[:description]
  end

  def introduction
    content[:introduction]
  end

  def content
    @content ||= _content
  end

  def avatar_src
    if avatar = @model.avatar
      avatar.external_link ? avatar.external_link : avatar.src
    else
      ""
    end
  end

  def fields
    %i(title description introduction)
  end
end
