module RoleControl
  class AccessDenied < StandardError; end

  module RoledController
    extend ActiveSupport::Concern

    included do
      before_action :check_controller_resources, except: :create
    end

    def check_controller_resources
      unless resources_exist?
        rejected_message = rejected_message(resource_ids)
        raise RoleControl::AccessDenied, rejected_message
      end
    end

    def resources_exist?
      resource_ids.blank? ? true : controlled_resources.exists?(id: resource_ids)
    end

    def controlled_resources
      @controlled_resources ||= api_user.do(controlled_scope)
        .to(resource_class, scope_context, add_active_scope: add_active_resources_scope)
        .with_ids(resource_ids)
        .scope
    end

    def controlled_scope
      action_name.to_sym
    end

    def rejected_message(denied_resource_ids)
      if denied_resource_ids.is_a?(Array)
        "Could not find #{resource_sym} with ids='#{denied_resource_ids.join(',')}'"
      else
        "Could not find #{resource_name} with id='#{denied_resource_ids}'"
      end
    end

    def resource_ids
      return @resource_ids if @resource_ids

      ids = resource_ids_from_params
      @resource_ids = if ids.length < 2
                        ids.first
                      else
                        ids
                      end
    end

    def resource_ids_from_params
      if respond_to?(:resource_name) && params.has_key?("#{ resource_name }_id")
        params["#{ resource_name }_id"]
      elsif params.has_key?(:id)
        params[:id]
      else
        ''
      end.split(',')
    end

    def scope_context
      {}
    end

    def add_active_resources_scope
      true
    end
  end
end
