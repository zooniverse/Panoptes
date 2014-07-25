require 'spec_helper'

def created_uss
  UserSeenSubject.where(params.except(:subject_id)).first
end

RSpec.describe UserSeenSubject, :type => :model do
  let(:user_seen_subject) { build(:user_seen_subject, subject_ids: []) }

  it "should have a valid factory" do
    expect(user_seen_subject).to be_valid
  end

  describe ".add_seen_subject_for_user" do
    let(:subject) { create(:subject) }
    let(:params) { { user_id: user_id, workflow_id: workflow_id, subject_id: subject.id } }

    context "when no user or workflow exists" do
      let(:workflow_id) { nil }
      let(:user_id) { nil }

      it "should fail" do
        expect do
          UserSeenSubject.add_seen_subject_for_user(params)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "user and workflow exist" do
      let(:workflow_id) { user_seen_subject.workflow.id }
      let(:user_id) { user_seen_subject.user.id }

      context "no user_seen_subject exists" do

        it "should create a new user_seen_subject" do
          expect do
            UserSeenSubject.add_seen_subject_for_user(params)
          end.to change{ UserSeenSubject.count }.by(1)
        end

        it "should add the subject id to the subject_ids array" do
          UserSeenSubject.add_seen_subject_for_user(params)
          expect(created_uss.subject_ids).to eq([ subject.id ])
        end
      end

      context "user_seen_subject for workflow and user exists" do
        let!(:save_uss) { user_seen_subject.save }

        it "should not create a new user_seen_subejct" do
          expect do
            UserSeenSubject.add_seen_subject_for_user(params)
          end.not_to change{ UserSeenSubject.count }
        end

        it "should add the subject id to the subject_ids array" do
          UserSeenSubject.add_seen_subject_for_user(params)
          user_seen_subject.reload
          expect(user_seen_subject.subject_ids).to include(subject.id)
        end
      end
    end
  end

  describe "#user" do
    it "should not be valid without a user" do
      expect(build(:user_seen_subject, user: nil)).to_not be_valid
    end

    it "should belong to a user" do
      expect(create(:user_seen_subject).user).to be_a(User)
    end
  end

  describe "#workflow" do
    it "should not be valid without a workflow" do
      expect(build(:user_seen_subject, workflow: nil)).to_not be_valid
    end

    it "should belong to a workflow" do
      expect(create(:user_seen_subject).workflow).to be_a(Workflow)
    end
  end

  describe "#add_subject_id" do
    let(:uss) { user_seen_subject }

    it "should not allow nil subject id's in the array" do
      s = build(:subject)
      expect{ uss.add_subject_id(s.id) }.to raise_error(UserSeenSubject::InvalidSubjectIdError)
    end

    it "should fail on a non-integer" do
      expect{ uss.add_subject_id("subject_id") }.to raise_error(UserSeenSubject::InvalidSubjectIdError)
    end

    it "should add a subject's id to the subject_ids array" do
      s = create(:subject)
      uss.add_subject_id(s.id)
      expect(uss.subject_ids).to include(s.id)
    end
  end
end
