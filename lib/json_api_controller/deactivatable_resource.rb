module JsonApiController
  module DeactivatableResource
    extend ActiveSupport::Concern

    included do
      before_action only: :destroy do |controller|
        controller.precondition_check
      end
    end

    def destroy
      Activation.disable_instances!(to_disable)

      to_disable.each do |resource|
        yield resource if block_given?
      end

      deleted_resource_response
    end

    def to_disable
      controlled_resources
    end
  end
end
