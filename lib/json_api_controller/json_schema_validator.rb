module JsonApiController
  class NoValidatorForActionError < StandardError
  end

  module JsonSchemaValidator
    extend ActiveSupport::Concern

    included do
      @action_params = Hash.new
      schema_actions = %i(update create) | Array.wrap(@extra_schema_actions)
      (@actions & schema_actions).each do |action|
        @action_params[action] = schema_class(action).try(:new)
      end
    end

    module ClassMethods
      def action_params
        @action_params
      end

      private

      def schema_class(action)
        "#{ resource_name }_#{ action }_schema".camelize.constantize
      rescue NameError
        nil
      end
    end

    protected

    def create_params
      params_for(:create)
    end

    def update_params
      params_for(:update)
    end

    def params_for(action=action_name.to_sym)
      ps = params.require(resource_sym).permit!
      if validator = self.class.action_params[action]
        validator.validate!(ps)
      else
        raise NoValidatorForActionError
      end
      ps
    end
  end
end
