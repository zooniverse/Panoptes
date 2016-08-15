class Api::V1::ProjectPreferencesController < Api::ApiController
  include PreferencesController

  require_authentication :all, scopes: [:project]
  resource_actions :create, :update, :show, :index, :update_settings
  extra_schema_actions :update_settings
  schema_type :json_schema
  before_action :validate_records, only: [:update_settings]

  def update_settings
    upp = UserProjectPreference.where(project_id: params_for[:project_id],
                                      user_id: params_for[:user_id]).first
    upp.settings.merge! params_for[:settings]
    upp.save!
    render status: :ok, nothing: true
  end

  private

  def validate_records
    User.find params_for[:user_id]
    p = Project.find params_for[:project_id]
    unless p.owner?(api_user.user)
      raise Api::Unauthorized.new ("You must be the project owner")
    end
  end

  def resource_name
    "project_preference"
  end
end
