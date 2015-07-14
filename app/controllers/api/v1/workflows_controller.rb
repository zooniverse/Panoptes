class Api::V1::WorkflowsController < Api::ApiController
  include Versioned
  include TranslatableResource

  doorkeeper_for :update, :create, :destroy, :retire_subject, scopes: [:project]
  before_action  :reject_live_project_changes, only: [ :create ]

  resource_actions :default
  schema_type :json_schema

  def show
    load_queue
    super
  end

  def create
    super { |workflow| refresh_queue(workflow) }
  end

  def update
    super { |workflow| refresh_queue(workflow) }
  end

  def update_links
    super { |workflow| refresh_queue(workflow) }
  end

  def destroy_links
    super { |workflow| refresh_queue(workflow) }
  end

  def retire_subject
    SubjectRetirementWorker.perform_async(params[:subject_id], params[:id])
    head :ok
  end

  private

  def context
    case action_name
    when "show", "index"
      { languages: current_languages }
    else
      {}
    end
  end

  def refresh_queue(workflow)
    ReloadQueueWorker.perform_async(workflow.id) if workflow.set_member_subjects.exists?
  end

  def load_queue
    SubjectQueueWorker.perform_async(params[:id], api_user.id)
  end

  def build_update_hash(update_params, id)
    if update_params.has_key? :tasks
      stripped_tasks, strings = extract_strings(update_params[:tasks])
      update_params[:tasks] = stripped_tasks
      Workflow.find(id).primary_content.update_attributes(strings: strings)
    end
    super(update_params, id)
  end

  def build_resource_for_create(create_params)
    stripped_tasks, strings = extract_strings(create_params[:tasks])
    create_params[:tasks] = stripped_tasks
    workflow = super(create_params)
    workflow.workflow_contents.build(strings: strings,
                                     language: workflow.primary_language)
    workflow
  end

  def extract_strings(tasks)
    task_string_extractor = TasksVisitors::ExtractStrings.new
    task_string_extractor.visit(tasks)
    [tasks, task_string_extractor.collector]
  end

  def new_items(resource, relation, value)
    items = construct_new_items(super(resource, relation, value), resource.project_id)
    if items.any? { |item| item.is_a?(SubjectSet) }
      items
    else
      items.first
    end
  end

  def construct_new_items(item_scope, workflow_project_id)
    Array.wrap(item_scope).map do |item|
      if item.is_a?(SubjectSet) && !item.belongs_to_project?(workflow_project_id)
        SubjectSetCopier.new(item, workflow_project_id).duplicate_subject_set_and_subjects
      else
        item
      end
    end
  end

  def reject_live_project_changes
    project = project_from_params
    if project && project.live
      raise Api::LiveProjectChanges.new("Can't create a workflow for a live project.")
    end
  end

  def project_from_params
    project_id = params_for[:links].try(:[], :project)
    if project_id && project = Project.find_by(id: project_id)
      project
    end
  end
end
