require 'spec_helper'

RSpec.describe RetirementWorker do
  let(:worker) { described_class.new }
  let(:sms) { create :set_member_subject }
  let(:workflow) { create :workflow, subject_sets: [sms.subject_set] }
  let(:count) { create(:subject_workflow_status, subject: sms.subject, workflow: workflow) }

  describe "#perform"  do
    context "sms is retireable" do
      before(:each) do
        allow_any_instance_of(SubjectWorkflowStatus).to receive(:retire?).and_return(true)
      end

      it 'should retire the subject for the workflow' do
        worker.perform(count)
        sms.reload
        expect(sms.retired_workflows).to include(workflow)
      end

      it 'should record a default reason for retirement' do
        expect { worker.perform(count) }.to change {
          count.reload.retirement_reason
        }.to("classification_count")
      end

      it 'should record the reason for retirement' do
        reason = "nothing_here"
        expect { worker.perform(count, reason) }.to change {
          count.reload.retirement_reason
        }.to(reason)
      end

      it 'should allow a nil reason for retirement' do
        expect { worker.perform(count, nil) }.not_to change {
          count.reload.retirement_reason
        }
      end

      it 'should call the workflow retired counter worker' do
        expect(WorkflowRetiredCountWorker)
          .to receive(:perform_async)
          .with(count.workflow.id)
        worker.perform(count.id)
      end

      it "should call the publish retire event worker" do
        expect(PublishRetirementEventWorker)
          .to receive(:perform_async)
          .with(workflow.id)
        worker.perform(count.id)
      end

      it "should notify the subject selector" do
        expect(NotifySubjectSelectorOfRetirementWorker)
          .to receive(:perform_async)
          .with(sms.subject_id, workflow.id)
        worker.perform(count.id)
      end
    end

    shared_examples "it does not run the post retirement workers" do
      it 'should not queue a notify selector retirement' do
        expect(NotifySubjectSelectorOfRetirementWorker).not_to receive(:perform_async)
        worker.perform(count)
      end

      it 'should not queue a retired count worker' do
        expect(WorkflowRetiredCountWorker).not_to receive(:perform_async)
        worker.perform(count)
      end

      it "should not call the publish retire event worker" do
        expect(PublishRetirementEventWorker).not_to receive(:perform_async)
        worker.perform(count.id)
      end
    end

    context "sms is not retireable" do
      it 'should not retire subject for the workflow' do
        allow_any_instance_of(SubjectWorkflowStatus).to receive(:retire?).and_return(false)
        worker.perform(count)
        sms.reload
        expect(sms.retired_workflows).to_not include(workflow)
      end

      it_behaves_like "it does not run the post retirement workers"
    end

    context 'when the sms is already retired' do
      before(:each) do
        allow(SubjectWorkflowStatus).to receive(:find).with(count.id).and_return count
        allow(count).to receive(:retired_at).and_return 1.minute.ago.utc
      end

      it 'should not retire the subject for the workflow' do
        expect(count).to_not receive :retire!
        worker.perform count.id
      end

      it_behaves_like "it does not run the post retirement workers"
    end
  end
end
