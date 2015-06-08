class SetMemberSubjectSerializer
  include RestPack::Serializer
  include BelongsToManyLinks
  include BlankTypeSerializer

  attributes :id, :created_at, :updated_at, :priority
  can_include :subject_set, :subject, :retired_workflows
end
