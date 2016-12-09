class ProjectPage < ActiveRecord::Base
  include Linkable
  include RoleControl::ParentalControlled
  include LanguageValidation

  has_paper_trail ignore: [:language]

  belongs_to :project

  can_through_parent :project, :show, :index, :versions, :version

  validates_uniqueness_of :url_key, scope: [:project_id, :language]

  def self.scope_for(action, user, opts={})
    case action
    when :show, :index
      super
    else
      translatable = Project.scope_for(:translate, user, opts)
      joins(:project).merge(translatable)
    end
  end
end
