require 'panoptes/restpack_serializer'

class SubjectSelectorSerializer
  include Panoptes::RestpackSerializer
  include NoCountSerializer

  attributes :id, :metadata, :locations, :zooniverse_id,
    :created_at, :updated_at, :href

  optional :retired, :already_seen, :finished_workflow

  preload :locations

  def self.model_class
    Subject
  end

  def locations
    @model.ordered_locations.map do |loc|
      {
       loc.content_type => loc.url_for_format(@context[:url_format] || :get)
      }
    end
  end

  def retired
    @model.retired_for_workflow?(workflow)
  end

  def already_seen
    !!(user_seen&.subjects_seen?(@model.id))
  end

  private

  def include_retired?
    select_context?
  end

  def include_already_seen?
    select_context?
  end

  def include_finished_workflow?
    select_context?
  end

  def select_context?
    @context[:select_context]
  end

  def workflow
    @context[:workflow]
  end

  def user
    @context[:user]
  end

  def user_seen
    @context[:user_seen]
  end

  def finished_workflow
    user&.has_finished?(workflow)
  end
end
