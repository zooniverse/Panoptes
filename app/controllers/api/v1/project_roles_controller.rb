class Api::V1::ProjectRolesController < Api::ApiController
  include RolesController
  require_authentication :create, :update, :destroy, scopes: [:project]

  allowed_params :create, roles: [], links: [:user, :project]
  allowed_params :update, roles: []

  def resource_name
    "project_role"
  end

  def update
    super
    UserAddedToProjectMailerWorker.perform_async(acl_user_id, controlled_resource.resource.id, roles) if new_roles_present?(roles)
  end

  def create
    super
    UserAddedToProjectMailerWorker.perform_async(new_user_id, project_id, roles) if new_roles_present?(roles)
  end

  private

  def roles
    params[:project_roles][:roles]
  end

  def acl_user_id
    controlled_resource.user_group.users.first.id.to_i
  end

  def new_user_id
    params[:project_roles][:links][:user].to_i
  end

  def project_id
    params[:project_roles][:links][:project].to_i
  end

  def new_roles_present?(roles)
    return false unless roles.present?
    (["collaborator", "expert"] & roles).present?
  end
end
