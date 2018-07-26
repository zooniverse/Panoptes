class UserGroupPolicy < ApplicationPolicy
  class Scope < Scope
    def private_query(action, roles)
      scope.joins(:memberships).merge(user.memberships_for(action, model))
        .where(memberships: { identity: false })
    end

    def user_can_access_scope(private_query)
      accessible = scope.where(id: private_query.select(:id))
      accessible = accessible.or(public_scope) if public_flag
      accessible
    end
  end

  class ReadScope < Scope
    roles_for_private_scope %i(group_admin group_member)

    def public_scope
      scope.where(private: false)
    end
  end

  class WriteScope < Scope
    roles_for_private_scope %i(group_admin)
  end

  scope :index, :show, :recents, with: ReadScope
  scope :update, :destroy, :update_links, :destroy_links, with: WriteScope

  def linkable_users
    # TODO: At the very least, this should filter out inactive users
    User.all
  end
end
