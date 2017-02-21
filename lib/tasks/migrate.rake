# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'csv'

namespace :migrate do

  namespace :user do
    desc "Migrate beta email users from input text file"
    task beta_email_communication: :environment do
      user_emails = CSV.read("#{Rails.root}/beta_users.txt").flatten!

      raise "Empty beta file list" if user_emails.blank?

      beta_users = User.where(beta_email_communication: nil, email: user_emails)
      beta_users_count = beta_users.count
      beta_users.update_all(beta_email_communication: true)
      puts "Updated #{ beta_users_count } users to receive emails for beta tests."
    end

    desc "Reset user sign_in_count"
    task reset_sign_in_count: :environment do
      user_logins = ENV['USERS'].try(:split, ",")
      query = User.where(migrated: true).where("sign_in_count > 1")
      if user_logins
        query = query.where(User.arel_table[:login].lower.in(user_logins.map(&:downcase)))
      end
      query.update_all(sign_in_count: 0)
    end

    desc "Set unsubscribe tokens for individual users"
    task setup_unsubscribe_token: :environment do
      unsubscribe_token_scope = User.where(unsubscribe_token: nil)
      missing_token_count = unsubscribe_token_scope.count
      unsubscribe_token_scope.find_each.with_index do |user, index|
        puts "#{ index } / #{ missing_token_count }" if index % 1_000 == 0
        if login = user.login
          token = UserUnsubscribeMessageVerifier.create_access_token(login)
          user.update_column(:unsubscribe_token, token)
        end
      end
      puts "Updated #{ missing_token_count } users have unsubscribe tokens."
    end

    desc "Create project preferences for projects classified on"
    task create_project_preferences: :environment do
      project = Project.find(ENV["PROJECT_ID"])

      if user = User.find_by(id: ENV["USER_ID"])
        p "Updating: #{user.login}"
        UserProjectPreference.create!(user: user, project: project)
      else
        query = User.joins(:classifications)
                .where(classifications: {project_id: project.id})
                .where.not(id: UserProjectPreference.where(project: project).select(:user_id))
                .distinct
        total = query.count
        query.find_each.with_index do |user, i|
          p "Updating: #{i+1} of #{total}"
          UserProjectPreference.create!(user: user, project: project)
        end
      end
    end

    desc "Sync user login/display_name with identity_group"
    task sync_logins: :environment do
      query = User.joins(:identity_group).where('"user_groups"."name" != "users"."login" OR "user_groups"."display_name" != "users"."display_name"')
      total = query.count
      query.find_each.with_index do |user, i|
        puts "Updating #{ i+1 } of #{total}"
        ig = user.identity_group
        ig.name = user.login
        ig.display_name = user.display_name
        ig.save(validate: false)
      end
    end

    desc "Set default value for whitelist upload count"
    task :upload_whitelist_default => :environment do
      User.where(upload_whitelist: nil).select("id").find_in_batches do |batch|
        User.where(id: batch.map(&:id)).update_all(upload_whitelist: false)
        print '.'
      end
      puts ' done'
    end
  end

  namespace :slug do
    desc "regenerate slugs"
    task regenerate: :environment do
      Project.find_each(&:save!)

      Collection.find_each(&:save!)
    end
  end

  namespace :recent do
    desc "Create missing recents from classifications"
    task create_missing_recents: :environment do
      query = Classification
              .joins("LEFT OUTER JOIN recents ON recents.classification_id = classifications.id")
              .where('recents.id IS NULL')
      total = query.count
      query.find_each.with_index do |classification, i|
        puts "#{i+1} of #{total}"
        Recent.create_from_classification(classification)
      end
    end

    desc "Remove all recents that have no traceable user in the classification"
    task remove_no_user_recents: :environment do
      no_user_recents = Recent.where(user_id: nil)
        .joins(:classification)
        .where(classifications: { user_id: nil })
        .select(:id)

      no_user_recents.find_in_batches.with_index do |batch, batch_index|
        puts "Processing relation ##{batch_index}"
        Recent.where(id: batch.map(&:id)).delete_all
      end
    end

    desc "Backfill belongs_to relations from classifications"
    task backfill_belongs_to_relations: :environment do
      scope = Recent.where(user_id: nil)
        .includes(:classification)
        .where.not(classifications: { user_id: nil })
        .preload(:subject)
      total = scope.count
      scope.find_each.with_index do |recent, i|
        # some recents are for non-logged in classifications
        next if recent.user_id || recent.classification.user_id.nil?
        puts "#{i+1} of #{total}"
        recent.send(:copy_classification_fkeys)
        recent.save!(validate: false) if recent.changed?
      end
    end
  end

  namespace :classification do
    desc "Add lifecycled at timestamps"
    task add_lifecycled_at: :environment do
      non_lifecycled = Classification.where(lifecycled_at: nil).select('id')
      non_lifecycled.find_in_batches do |classifications|
        Classification.where(id: classifications.map(&:id))
        .update_all(lifecycled_at: Time.current.to_s(:db))
      end
    end

    desc "Convert non-standard Wildcam survey annotations"
    task wildcam_annotations: :environment do
      Classification.where(workflow_id: 338).find_each do |classification|
        next if classification.metadata["converted_legacy_survey_format"]

        new_annotations = classification.annotations.map do |annotation|
          if annotation["task"] == "survey"
            annotation.merge("task" => "T1", "value" => Array.wrap(annotation["value"]))
          else
            annotation
          end
        end

        new_metadata = classification.metadata.merge("converted_legacy_survey_format" => true)

        classification.update_columns annotations: new_annotations, metadata: new_metadata
      end
    end
  end

  namespace :tutorial do
    desc "Associate all workflows with tutorials"
    task :workflowize => :environment do
      Tutorial.find_each do |tutorial|
        tutorial.workflows = tutorial.project.workflows.where(active: true)
        tutorial.save!
        print '.'
      end
    end
  end

  namespace :project_page do
    desc "Rename Project page result keys"
    task :rename_result_pages => :environment do
      result_pages = ProjectPage.where(url_key: 'result', title: 'Result')
      result_pages.update_all(url_key: 'results', title: 'Results')
    end
  end

  namespace :subjects do
    desc "Set default value for subject activated_state"
    task :activated_state_default => :environment do
      scope = Subject.unscoped
      subjects = scope.where(activated_state: nil).select(:id)
      subjects.find_in_batches do |batch|
        scope.where(id: batch.map(&:id)).update_all(activated_state: 0)
        print '.'
      end
      puts ' done'
    end
  end

  namespace :workflows do
    desc "Set the workflows version cache key attribute"
    task :update_version_cache_key => :environment do
      Workflow.where(current_version_number: nil).find_each do |w|
        w.send(:update_workflow_version_cache)
      end
    end
  end

  namespace :workflow_contents do
    desc "Set the workflow_contents version cache key attribute"
    task :update_version_cache_key => :environment do
      WorkflowContent.where(current_version_number: nil).find_each do |wc|
        wc.send(:update_workflow_version_cache)
      end
    end
  end
end
