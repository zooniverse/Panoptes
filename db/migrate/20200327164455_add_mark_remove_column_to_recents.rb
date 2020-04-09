# frozen_string_literal: true

class AddMarkRemoveColumnToRecents < ActiveRecord::Migration
  disable_ddl_transaction!
  def up
    add_column :recents, :mark_remove, :boolean
    change_column_default :recents, :mark_remove, false
    remove_foreign_key :recents, :classifications

    remove_old_recents
    mark_all_remaining_recents_as_good
    remove_bloated_indexes
    rebuild_used_indexes
  end

  def down
    remove_column :recents, :mark_remove
    add_foreign_key :recents, :classifications
  end

  private

  def remove_old_recents
    # find the first known recent older than 2 week
    recent_older_than_2_weeks = Recent.first_older_than(14.days)
    return unless recent_older_than_2_weeks

    # use the oldest recent id to destroy old recents
    old_recents_to_remove = Recent.where(
      'id <= ?',
      recent_older_than_2_weeks.id
    ).select(:id)

    old_recents_to_remove.find_in_batches do |recents|
      Recent.where(id: recents).destroy_all
    end
  end

  def mark_all_remaining_recents_as_good
    # as all remaining recents in the table are less
    # than 14 days old, mark them as ok to keep
    Recent.select(:id).find_in_batches do |recents|
      Recent.where(id: recents).update_all(mark_remove: false)
    end
  end

  # remove recents bloated indexes after data cleanup
  def remove_bloated_indexes
    %i[project_id subject_id user_id workflow_id created_at].each do |col|
      remove_index :recents, column: col if index_exists?(:recents, col)
    end
  end

  # rebuild only recent indexes we use to access data
  def rebuild_used_indexes
    add_index :recents, :project_id, algorithm: :concurrently
    add_index :recents, :user_id, algorithm: :concurrently
  end
end
