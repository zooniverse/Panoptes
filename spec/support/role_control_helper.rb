def setup_role_control_tables
  mock_active_record_model(:controlled) do |t|
    t.string(:another_field)
    t.boolean(:private, default: true)
  end

  mock_active_record_model(:test_parent_control) do |t|
    t.integer(:controlled_table_id)
  end

  unless const_defined?("ControlledTable")
    Object.const_set("ControlledTable",
                     Class.new(ActiveRecord::Base) do
                       has_many :access_control_lists, as: :resource
                     end)
  end

  unless const_defined?("ControlledTablePolicy")
    Object.const_set("ControlledTablePolicy",
                     Class.new(ApplicationPolicy) do
                       index_scope = Class.new(ApplicationPolicy::Scope) do
                         roles_for_private_scope %(admin)
                       end

                       read_scope = Class.new(ApplicationPolicy::Scope) do
                         roles_for_private_scope %i(admin test_role)

                         def public_scope
                           scope.where(private: false)
                         end
                       end

                       write_scope = Class.new(ApplicationPolicy::Scope) do
                         roles_for_private_scope %(test_role)
                       end

                       scope :index, with: index_scope
                       scope :read, :show, with: read_scope
                       scope :update, with: write_scope
                     end)
  end
end

def create_roles_join_instance(roles, controlled_resource, actor)
  AccessControlList.create! do |rmt|
    rmt.roles = roles
    rmt.resource = controlled_resource
    rmt.user_group = actor.identity_group
  end
end
