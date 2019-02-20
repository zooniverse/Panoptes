module Export
  module JSON
    class Project
      attr_reader :project

      def self.project_attributes
        %w( name display_name primary_language configuration urls slug description introduction workflow_description url_labels)
      end

      def self.media_attributes
        %w( type content_type src path_opts external_link metadata )
      end

      def self.workflow_attributes
        %w( display_name tasks pairwise grouped prioritized primary_language
            first_task tutorial_subject_id strings )
      end

      def initialize(project_id)
        @project = ::Project.where(id: project_id).includes(:workflows).first
      end

      def to_json
        {}.tap do |export|
          export[:project] = project_attrs
          export[:project_avatar] = avatar_attrs
          export[:project_background] = background_attrs
          export[:workflows] = workflows_attrs
        end.to_json
      end

      private

      def project_workflows
        project.workflows
      end

      def model_attributes(model, attrs)
        model.try(:as_json).try(:slice, *attrs).tap do |model_attrs|
          yield model_attrs if block_given?
        end
      end

      def project_attrs
        model_attributes(project, self.class.project_attributes) do |project_hash|
          project_hash.merge!(private: true)
        end
      end

      def avatar_attrs
        model_attributes(project.avatar, self.class.media_attributes)
      end

      def background_attrs
        model_attributes(project.background, self.class.media_attributes)
      end

      def workflows_attrs
        [].tap do |workflows|
          project_workflows.each do |workflow|
            workflows << model_attributes(workflow, self.class.workflow_attributes)
          end
        end
      end
    end
  end
end
