require 'spec_helper'

RSpec.describe Recent, :type => :model do
  describe "association validations" do
    let(:classification) { create(:classification) }
    let(:recent) { build(:recent, classification: classification) }

    it 'should not be valid without a classification' do
      recent.classification = nil
      expect(recent).to_not be_valid
    end

    it 'should not be valid without a subject' do
      recent.subject = nil
      expect(recent).to_not be_valid
    end

    it 'should not be valid without a user_id' do
      allow(classification).to receive(:user_id).and_return(nil)
      recent.user_id = nil
      expect(recent).to_not be_valid
    end

    it 'should not be valid without a project_id' do
      allow(classification).to receive(:project_id).and_return(nil)
      recent.project_id = nil
      expect(recent).to_not be_valid
    end

    it 'should not be valid without a workflow_id' do
      allow(classification).to receive(:workflow_id).and_return(nil)
      recent.workflow_id = nil
      expect(recent).to_not be_valid
    end

    it 'should be valid without a user_group_id' do
      allow(classification).to receive(:user_group_id).and_return(nil)
      recent.user_group_id = nil
      expect(recent).to be_valid
    end
  end

  describe "::create_from_classification" do
    let(:classification) { create(:classification) }

    it 'should create recent for each subject' do
      subjects = classification.subject_ids
      expect {
        Recent.create_from_classification(classification)
      }.to change {
        Recent.where(subject_id: subjects).count
      }.by (subjects.length)
    end
  end

  describe ':first_older_than' do
    let(:old_period) { 15.days }
    let(:old_recent) do
      create(:recent) do |r|
        r.update_attribute(:created_at, Time.now.utc - old_period)
      end
    end
    let(:create_attrs) do
      {
        classification: old_recent.classification,
        subject: old_recent.subject
      }
    end
    let(:new_recent) { create(:recent, create_attrs) }

    it 'returns nothing if no recents to find' do
      expect(described_class.first_older_than).to be_nil
    end

    # avoid factories taking seconds to setup, collapsing to one test
    it 'finds the correct records based on default and supplied periods' do # rubocop:disable RSpec/MultipleExpectations
      # ensure these are created in this order
      old_recent
      new_recent
      expect(described_class.first_older_than.id).to eq(old_recent.id)
      expect(described_class.first_older_than(0.days).id).to eq(new_recent.id)
    end
  end

  describe "ordered_locations" do
    it_behaves_like "it has ordered locations" do
      let(:resource) { create(:recent) }
      let(:klass) { Recent }
    end
  end
end
