class Organization < ActiveRecord::Base
  include RoleControl::Owned
  include RoleControl::Controlled
  include Activatable
  include Linkable
  include Translatable

  scope :public_scope, -> { where.not(listed_at: nil) }
  scope :private_scope, -> { where(listed_at: nil) }

  has_many :projects
  has_many :acls, class_name: "AccessControlList", as: :resource, dependent: :destroy
  has_one :avatar, -> { where(type: "organization_avatar") }, class_name: "Medium", as: :linked
  has_one :background, -> { where(type: "organization_background") }, class_name: "Medium", as: :linked
  has_many :organization_roles, -> { where.not(roles: []) }, class_name: "AccessControlList", as: :resource
  has_many :pages, class_name: "OrganizationPage", dependent: :destroy

  accepts_nested_attributes_for :organization_contents

  can_by_role :destroy, :update, :update_links, :destroy_links, roles: [ :owner, :collaborator ]

  can_by_role :show, :index, :versions, :version, public: true,
    roles: [ :owner, :collaborator, :tester, :translator, :scientist, :moderator ]

  can_by_role :translate, roles: [ :owner, :translator, :collaborator ]

  can_be_linked :project, :scope_for, :update, :user
  can_be_linked :access_control_list, :scope_for, :update, :user

end
