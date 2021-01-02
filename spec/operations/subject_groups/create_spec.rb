# frozen_string_literal: true

require 'spec_helper'

describe SubjectGroups::Create do
  let(:project) { create :project }
  let(:user) { project.owner }
  let(:subjects) do
    create_list(:subject, 2, :with_mediums, num_media: 1, project: project, uploader: user)
  end
  let(:subject_ids) { subjects.map(&:id) }
  let(:operation) { described_class.with(api_user: nil) }
  let(:created_subject_group) do
    operation.run!(subject_ids: subject_ids, uploader_id: user.id.to_s, project_id: project.id.to_s)
  end

  it 'creates creates a valid subject_group' do
    expect(created_subject_group).to be_valid
  end

  it 'raises with error if it can not find all the subject_ids' do
    incorrect_subject_ids = subject_ids | ['-1']
    expect {
      operation.run!(subject_ids: incorrect_subject_ids, uploader_id: user.id.to_s, project_id: project.id.to_s)
    }.to raise_error(Operation::Error, 'Number of found subjects does not match the size of param subject_ids')
  end

  it 'sets the subject_group key' do
    expect(created_subject_group.key).to match(subject_ids.join('-'))
  end

  it 'respects the order of the subject_ids in the key' do
    reverse_key_subject_group = operation.run!(subject_ids: subject_ids.reverse, uploader_id: user.id.to_s, project_id: project.id.to_s)
    expect(reverse_key_subject_group.key).to match(subject_ids.reverse.join('-'))
  end

  describe 'group_subject' do
    it 'creates the group_subject' do
      subjects
      expect { created_subject_group }.to change(Subject, :count).by(1)
    end

    it 'uses creates external media locations' do
      group_subject = created_subject_group.group_subject
      external_locations = group_subject.locations.map(&:external_link)
      expect(external_locations).to match_array(Array.new(subjects.size, true))
    end

    it 'creates the locations based on the subject data order' do
      locations_in_order = subjects.map(&:locations).flatten
      expected_locations = locations_in_order.map { |loc| "https://#{loc.src}" }
      result_locations = created_subject_group.group_subject.locations.map(&:src)
      expect(result_locations).to match(expected_locations)
    end

    describe 'tracking the subject group info in the group_subject metadata' do
      let(:group_subject) { created_subject_group.group_subject }

      it 'records the subject_group id in hidden metadata attribute' do
        expect(group_subject.metadata['#subject_group_id']).to match(created_subject_group.id)
      end

      it 'records the group subject ids in hidden metadata attribute' do
        expect(group_subject.metadata['#group_subject_ids']).to match(created_subject_group.key)
      end
    end
  end
end
