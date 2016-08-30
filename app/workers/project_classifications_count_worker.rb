class ProjectClassificationsCountWorker
  include Sidekiq::Worker

  sidekiq_options congestion: {
    interval: 15,
    max_in_interval: 1,
    min_delay: 0,
    reject_with: :reschedule,
    key: ->(project_id) {
      "project_#{project_id}_classifications_count_worker"
    }
  }

  def perform(project_id)
    project = Project.find(project_id)
    project.workflows.map do |workflow|
      counter = WorkflowCounter.new(workflow)
      workflow.update_column(:classifications_count, counter.classifications)
    end
    counter = ProjectCounter.new(project)
    project.update_column(:classifications_count, counter.classifications)
  end
end
