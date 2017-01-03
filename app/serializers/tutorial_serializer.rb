class TutorialSerializer
  include RestPack::Serializer
  include MediaLinksSerializer
  include CachedSerializer

  attributes :steps, :href, :id, :created_at, :updated_at, :language, :kind, :display_name

  can_include :project
  can_include :workflows
  media_include :attached_images
end
