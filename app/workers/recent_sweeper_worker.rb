# frozen_string_literal: true

class RecentSweeperWorker
  include Sidekiq::Worker

  include Sidetiq::Schedulable

  sidekiq_options queue: :data_low

  recurrence { hourly }

  def perform
    # mark any recents older than 14 days, keep the recents table clean
    mark_old_recents(Recent.first_older_than(14.days))

    # https://api.rubyonrails.org/classes/ActiveRecord/Batches.html#method-i-in_batches
    # move this method to in_batches when migrating past rails 4
    recent_ids_to_delete = Recent.where(mark_remove: true).select(:id)
    recent_ids_to_delete.find_in_batches do |recents|
      Recent.where(id: recents).destroy_all
    end
  end

  def mark_old_recents(old_recent)
    return unless old_recent

    old_recents = Recent.where('id <= ?', old_recent.id).select(:id)

    old_recents.find_in_batches do |recents|
      Recent.where(
        id: recents,
        mark_remove: false
      ).update_all(mark_remove: true)
    end
  end
end
