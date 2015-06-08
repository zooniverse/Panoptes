class CollectionSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include FilterHasMany
  include BlankTypeSerializer

  attributes :id, :name, :display_name, :created_at, :updated_at,
    :slug
  can_include :project, :owner
  can_filter_by :display_name, :slug
end
