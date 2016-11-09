module FilterByCurrentUserRoles
  extend ActiveSupport::Concern

  included do
    before_action :add_roles_to_filter_params!, only: :index
  end

  def add_roles_to_filter_params!
    roles_filter = params.delete(:current_user_roles).try(:split, ",")
    if !roles_filter.blank? && api_user.logged_in?
      @controlled_resources = controlled_resources
        .joins(:access_control_lists)
        .where(access_control_lists: {user_group_id: api_user.user.identity_group.id})
        .where.overlap(access_control_lists: { roles: roles_filter })
        .preload(
          owner: { identity_membership: :user }
        )
    end
  end
end
