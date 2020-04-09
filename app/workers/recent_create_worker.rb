class RecentCreateWorker
  include Sidekiq::Worker

  def perform(classification_id)
    classification = Classification.find(classification_id)
    recents = Recent.create_from_classification(classification)
    latest_recent_id = recents.last.id

    # find the latest set of user / project recents
    # and make sure we order them descending on the PK (i.e. latest are first)
    latest_ordered_user_project_recents = Recent.where(
      project_id: classification.project_id,
      user_id: classification.user_id
    ).order(id: 'DESC')

    mark_remove_recents_past_limit(
      latest_ordered_user_project_recents,
      latest_recent_id
    )
  end

  private

  def mark_remove_recents_past_limit(latest_ordered_user_project_recents, latest_recent_id)
    # find the latest recent id up to the limit of stored recents
    # taking care to set a starting point to search the PK index
    # using the created recent id from this worker
    # this will help avoid traversing the possibly large table space of recents
    oldest_allowed_recent_id =
      latest_ordered_user_project_recents
      .where('id <= ?', latest_recent_id)
      .offset(Panoptes.user_project_recents_limit)
      .limit(1)
      .pluck(:id)
      .last

    # gaurd against recents coming in under the limit
    return unless oldest_allowed_recent_id

    # search and mark_remove all the the recents
    # that are over the allowed limit of records
    # taking care to update only older recents smaller than (older)
    # the known recent id at the limit boundary
    latest_ordered_user_project_recents
      .where('id < ?', oldest_allowed_recent_id)
      .update_all(mark_remove: true)
  end
end
