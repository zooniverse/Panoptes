class Api::V1::MembershipsController < Api::ApiController
  before_filter :require_login
  require_authentication :all, scopes: [:group]
  resource_actions :index, :show, :create, :update, :deactivate
  schema_type :strong_params

  allowed_params :update, :state

  def create
    resources = resource_class.transaction(requires_new: true) do
      Array.wrap(params[:memberships]).map do |membership_params|
        operation.run!(membership_params)
      end
    end

    created_resource_response(resources)
  end

  private

  def policy_object
    RoledControllerPolicy.new(api_user, resource_class, resource_name, action_name, params, add_active_resources_scope: false)
  end
end
