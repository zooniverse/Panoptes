class Recent < ActiveRecord::Base
  include OrderedLocations

  belongs_to :classification
  belongs_to :subject

  has_many :locations, through: :subject

  belongs_to :project
  belongs_to :workflow
  belongs_to :user
  belongs_to :user_group

  validates_presence_of :classification, :subject, :project_id, :workflow_id, :user_id

  before_validation :copy_classification_fkeys

  def self.create_from_classification(classification)
    classification.subject_ids.map do |subject_id|
      create!(subject_id: subject_id, classification: classification)
    end
  end

  # find the first known recent older than 2 week (defaul)
  def self.first_older_than(period=14.days)
    where('created_at < ?', Time.now.utc - period)
      .order(id: 'desc')
      .limit(1)
      .first
  end

  private

  def copy_classification_fkeys
    if classification
      %w(project_id workflow_id user_id user_group_id).each do |key|
        send("#{key}=", classification.send(key))
      end
    end
  end
end
