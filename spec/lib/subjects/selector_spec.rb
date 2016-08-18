require 'spec_helper'

RSpec.describe Subjects::Selector do
  let(:workflow) { create(:workflow_with_subjects) }
  let(:user) { create(:user) }
  let(:smses) { create_list(:set_member_subject, 10).reverse }
  let(:params) { {} }
  let(:subject_queue) do
    create(:subject_queue,
           workflow: workflow,
           user: nil,
           subject_set: nil,
           set_member_subjects: smses)
  end

  subject { described_class.new(user, workflow, params, Subject.all) }

  describe "#get_subjects" do
    it 'should return url_format: :get in the context object' do
      subject_queue
      _, ctx = subject.get_subjects
      expect(ctx).to include(url_format: :get)
    end

    context "when the user doesn't have a queue" do
      it 'should create a new queue from the logged out queue' do
        subject_queue
        expect(SubjectQueue).to receive(:create_for_user)
          .with(workflow, user, set_id: nil).and_call_original
        subject.get_subjects
      end

      context "when the workflow doesn't have any subject sets" do
        it 'should raise an informative error' do
          allow_any_instance_of(Workflow).to receive(:subject_sets).and_return([])
          expect{subject.get_subjects}.to raise_error(Subjects::Selector::MissingSubjectSet,
            "no subject set is associated with this workflow")
        end
      end

      context "when the subject sets have no data" do
        it 'should raise the an error' do
          allow_any_instance_of(Workflow)
            .to receive(:set_member_subjects).and_return([])
          message = "No data available for selection"
          expect {
            subject.get_subjects
          }.to raise_error(Subjects::Selector::MissingSubjects, message)
        end
      end
    end

    context "queue is stale" do
      let(:subject_queue) do
        create(:subject_queue,
               workflow: workflow,
               user: user,
               set_member_subject_ids: (1..10).to_a)
      end
      before do
        subject_queue
        allow_any_instance_of(SubjectQueue).to receive(:stale?).and_return(true)
      end

      it 'should ignore the subject queue and request strategy selection', :aggregate_failures do
        selector = instance_double("Subjects::StrategySelection")
        expect(selector).to receive(:select).and_return([1])
        expect(Subjects::StrategySelection).to receive(:new).and_return(selector)
        expect_any_instance_of(SubjectQueue).to receive(:update_ids).with([])
        subject.get_subjects
      end

      context "when the params page size is set as a string" do
        let(:size) { 2 }
        subject do
          params = { page_size: size }
          described_class.new(user, workflow, params, Subject.all)
        end

        it 'should return the page_size number of subjects' do
          subject_queue
          subjects, _context = subject.get_subjects
          expect(subjects.length).to eq(size)
        end
      end
    end

    context "queue is empty" do
      let(:subject_queue) do
        create(:subject_queue,
               workflow: workflow,
               user: user,
               subject_set: queue_subject_set,
               set_member_subjects: [])
      end
      let(:subject_set) { workflow.subject_sets.first }
      let(:queue_subject_set) { nil }

      before do
        create_list(:set_member_subject, 10, subject_set: subject_set)
        subject_queue
      end

      it 'should return the default subjects set size' do
        subjects, = subject.get_subjects
        expect(subjects.length).to eq(10)
      end

      context "when the database selection strategy returns an empty set" do
        let(:queue_subject_set) { subject_set }

        before do
          allow_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:select).and_return([])
          expect_any_instance_of(Subjects::PostgresqlSelection)
            .to receive(:any_workflow_data)
            .and_call_original
        end

        it 'should fallback to selecting some data' do
          subjects, _context = subject.get_subjects
        end

        context "and the workflow is grouped" do
          let(:subject_set_id) { subject_set.id }
          let(:params) { { subject_set_id: subject_set_id } }

          it 'should fallback to selecting some grouped data' do
            allow_any_instance_of(Workflow).to receive(:grouped).and_return(true)
            subjects, _context = subject.get_subjects
          end
        end
      end
    end

    describe "queue management" do
      let(:smses) { workflow.set_member_subjects }
      let(:sms_ids) { smses.map(&:id) }
      let(:subject_queue) do
        create(:subject_queue,
               workflow: workflow,
               user: queue_owner,
               subject_set: nil,
               set_member_subjects: smses)
      end

      before(:each) { subject_queue }

      context "when the user has a queue" do
        let(:queue_owner) { user }

        it 'should dequeue the ids from the users queue' do
          expect{
            subject.get_subjects
          }.to change {
            subject_queue.reload.set_member_subject_ids.length
          }.from(sms_ids.length).to(0)
        end

        context "when the queue object is not stale" do
          it "should dequeue inline" do
            expect_any_instance_of(SubjectQueue)
              .to receive(:dequeue_update)
              .with(array_including(sms_ids))
            subject.get_subjects
          end
        end

        context "when the queue object is stale" do
          it "should catch the error and push into the background" do
            allow(subject)
              .to receive(:find_subject_queue)
              .and_return(subject_queue)
            allow(subject_queue)
              .to receive(:dequeue_update)
              .and_raise(ActiveRecord::StaleObjectError.new(subject_queue, :update))
            expect(DequeueSubjectQueueWorker).to receive(:perform_async)
              .with(subject_queue.id, array_including(sms_ids))
            subject.get_subjects
          end
        end
      end

      context "when the queue has no user" do
        let(:queue_owner) { nil }
        let(:user) { nil }

        # anonymous site users can cause a lot of contention on updates
        # to the non-logged in queues, use the rate limiter in sidekiq to
        # control how often these happen
        it 'should schedule a dequeue for the non-logged in queue' do
          expect(NonLoggedInDequeueSubjectQueueWorker).to receive(:perform_async)
            .with(subject_queue.id, array_including(sms_ids))
          subject.get_subjects
        end
      end

      describe "non-logged in queues" do
        let(:queue_owner) { nil }

        shared_examples "creates for the logged out user" do

          it 'should create for logged out user' do
            expect(SubjectQueue)
              .to receive(:create_for_user)
              .with(workflow, nil, set_id: nil)
              .and_call_original
            subject.get_subjects
          end

          it 'should raise an error if it cannot find a queue' do
            expect(SubjectQueue)
              .to receive(:create_for_user)
              .with(workflow, nil, set_id: nil)
              .and_return(nil)
            expect { subject.get_subjects }.to raise_error(Subjects::Selector::MissingSubjectQueue)
          end
        end

        context "when the workflow is finished" do
          before(:each) do
            allow_any_instance_of(Workflow).to receive(:finished?).and_return(true)
          end

          context "when the logged_out queue doesn't exist" do
            let(:queue_owner) { user }

            it_behaves_like "creates for the logged out user"
          end
        end

        context "when the user has finished the workflow" do
          before(:each) do
            allow_any_instance_of(User).to receive(:has_finished?).and_return(true)
          end

          context "when the logged_out queue doesn't exist" do
            let(:queue_owner) { user }

            it_behaves_like "creates for the logged out user"
          end
        end
      end
    end
  end

  describe '#selected_subjects' do

    context "with retired subjects" do
      let(:retired_workflow) { workflow }
      let(:sms) { smses[0] }
      let!(:swc) do
        create(:subject_workflow_status,
          subject: sms.subject,
          workflow: retired_workflow,
          retired_at: Time.zone.now
        )
      end
      let(:result) do
        subject.selected_subjects(subject_queue).map do |s|
          s.set_member_subjects.first.id
        end
      end

      it 'should not return retired subjects' do
        expected = subject_queue.set_member_subject_ids[1..-1]
        expect(result).to match_array(expected)
      end

      context "when the sms is retired for a different workflow" do
        let(:retired_workflow) { create(:workflow, project: workflow.project) }

        it 'should return all the subjects' do
          expected = subject_queue.set_member_subject_ids
          expect(result).to match_array(expected)
        end
      end
    end

    it 'should not return deactivated subjects' do
      deactivated_ids = smses[0..smses.length-2].map(&:subject_id)
      Subject.where(id: deactivated_ids).update_all(activated_state: 1)
      result = subject.selected_subjects(subject_queue).map(&:id)
      expect(result).not_to include(*deactivated_ids)
    end

    it 'should return something when everything in the queue is retired' do
      smses.each do |sms|
        swc = create(:subject_workflow_status, subject: sms.subject, workflow: workflow, retired_at: Time.zone.now)
      end
      expect(subject.selected_subjects(subject_queue).size).to be > 0
    end

    it "should respect the order of the sms selection" do
      ordered_sms = smses.sample(5)
      sms_ids = ordered_sms.map(&:id)
      expect(subject).to receive(:run_strategy_selection).and_return(sms_ids)
      subjects = subject.selected_subjects(double(stale?: true, update_ids: nil))
      expect(ordered_sms.map(&:subject_id)).to eq(subjects.map(&:id))
    end

    context "feature flip straight selection over queues" do
      it 'should use queue selection when feature is off' do
        expect(subject).to receive(:sms_ids_from_queue).and_call_original
        subject.selected_subjects(subject_queue)
      end

      it 'should skip queue selection when feature is on' do
        Panoptes.flipper[:skip_queue_selection].enable
        expect(subject).to receive(:run_strategy_selection).and_call_original
        subject.selected_subjects(subject_queue)
      end
    end
  end
end
