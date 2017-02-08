class WorkflowClassificationsCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  sidekiq_options congestion: {
    interval: 60,
    max_in_interval: 1,
    min_delay: 10,
    reject_with: :reschedule,
    key: ->(workflow_id) {
      "workflow_#{workflow_id}_classifications_count_worker"
    }
  }

  sidekiq_options unique: :until_executing

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    counter = WorkflowCounter.new(workflow)
    workflow.update_column(:classifications_count, counter.classifications)

    ProjectClassificationsCountWorker.perform_async(workflow.project.id)
  end
end
