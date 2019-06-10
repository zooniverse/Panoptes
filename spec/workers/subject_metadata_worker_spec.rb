require "spec_helper"

RSpec.describe SubjectMetadataWorker do
  let(:user) { create :user }
  let(:project) { create :project_with_workflow, owner: user }
  let(:workflow) { project.workflows.first }
  let(:subject_set) { create(:subject_set_with_subjects, project: project, workflows: [workflow]) }

  subject(:worker) { SubjectMetadataWorker.new }

  before do
    subject_set.subjects[0].metadata['#priority'] = 1
    subject_set.subjects[1].metadata['#priority'] = "2"
    subject_set.subjects[1].metadata['#training_subject'] = "true"
    subject_set.subjects.map(&:save)
  end

  describe "#perform" do
    it 'copies priority from metadata to SMS attribute' do
      worker.perform(subject_set.id)
      sms_one = SetMemberSubject.find_by_subject_set_id_and_subject_id(subject_set.id, subject_set.subjects[0])
      sms_two = SetMemberSubject.find_by_subject_set_id_and_subject_id(subject_set.id, subject_set.subjects[1])
      expect(sms_one.priority).to eq(1)
      expect(sms_two.priority).to eq(2)
    end

    # it 'copies training_subject from metadata to SMS attribute' do
    #   worker.perform(subject_set.set_member_subjects.pluck(:id))
    #   sms_one = SetMemberSubject.find_by_subject_set_id_and_subject_id(subject_set.id, subject_set.subjects[0])
    #   sms_two = SetMemberSubject.find_by_subject_set_id_and_subject_id(subject_set.id, subject_set.subjects[1])
    #   expect(sms_one.training_subject).to be_nil
    #   expect(sms_two.training_subject).to be_true
    # end
  end
end
