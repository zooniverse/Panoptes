class SubjectSelector
  class MissingParameter < StandardError; end
  class MissingSubjectQueue < StandardError; end
  class MissingSubjectSet < StandardError; end

  attr_reader :user, :params, :workflow

  def initialize(user, workflow, params, scope)
    @user, @workflow, @params, @scope = user, workflow, params, scope
  end

  def queued_subjects
    raise workflow_id_error unless workflow
    raise group_id_error if needs_set_id?
    raise missing_subject_set_error if workflow.subject_sets.empty?

    queue, context = retrieve_subject_queue

    if queue
      set_member_subject_ids = queue.next_subjects(subjects_page_size)
      selection_scope = if set_member_subject_ids.blank?
        select_from_database
      else
        set_member_subject_ids
      end
      selected_subjects(selection_scope, context)
    else
      raise MissingSubjectQueue.new("No queue defined for user. Building one now, please try again.")
    end
  end

  def selected_subjects(sms_ids, selector_context={})
    subjects = @scope.eager_load(:set_member_subjects)
      .where(set_member_subjects: {id: sms_ids})
      .order("idx(array[#{sms_ids.join(',')}], set_member_subjects.id)")
    [subjects, selector_context.merge(selected: true, url_format: :get)]
  end

  private

  def select_from_database
    PostgresqlSelection.new(workflow, user.user)
      .select(limit: 5, subject_set_id: params[:subject_set_id])
  end

  def needs_set_id?
    workflow.grouped && !params.has_key?(:subject_set_id)
  end

  def workflow_id_error
    MissingParameter.new("workflow_id parameter missing")
  end

  def group_id_error
    MissingParameter.new("subject_set_id parameter missing for grouped workflow")
  end

  def missing_subject_set_error
    MissingSubjectSet.new("no subject set is associated with this workflow")
  end

  def subjects_page_size
    page_size = params[:page_size] ? params[:page_size].to_i : 10
    params.merge!(page_size: page_size)
    page_size
  end

  def retrieve_subject_queue
    queue_user, context = if workflow.finished? || user.has_finished?(workflow)
                            [nil, {workflow: workflow,
                                   user_seen: UserSeenSubject.where(user: user.user, workflow: workflow)}]
                          else
                            [user.user, {}]
                          end

    queue = SubjectQueue.by_set(params[:subject_set_id])
      .find_by(user: queue_user, workflow: workflow)

    case
    when queue.nil?
      queue = SubjectQueue.create_for_user(workflow, queue_user, set: params[:subject_set_id])
    when queue.below_minimum?
      EnqueueSubjectQueueWorker.perform_async(workflow.id, queue_user.try(:id))
    end
    [queue, context]
  end
end
