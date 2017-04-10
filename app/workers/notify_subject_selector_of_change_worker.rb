class NotifySubjectSelectorOfChangeWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3, queue: :data_high

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    workflow.subject_selector.reload_workflow
  rescue ActiveRecord::RecordNotFound
  end
end
