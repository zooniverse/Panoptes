require 'spec_helper'

RSpec.describe RetirementWorker do
  let(:worker) { described_class.new }
  let(:sms) { create :set_member_subject }
  let(:workflow) { create :workflow, subject_sets: [sms.subject_set] }
  let(:count) { create(:subject_workflow_status, subject: sms.subject, workflow: workflow) }

  describe "#perform" do
    context "sms is retireable" do
      before(:each) do
        allow_any_instance_of(SubjectWorkflowStatus).to receive(:retire?).and_return(true)
      end

      it 'should retire the subject for the workflow' do
        worker.perform(count)
        sms.reload
        expect(sms.retired_workflows).to include(workflow)
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

      context "when the workflow is not using cellect" do
        it "should not call the retire cellect worker" do
          expect(RetireCellectWorker).not_to receive(:perform_async)
          worker.perform(count.id)
        end
      end

      context "when the workflow is using cellect" do
        before do
          allow(Panoptes).to receive(:cellect_on).and_return(true)
          allow_any_instance_of(Workflow)
          .to receive(:using_cellect?).and_return(true)
        end

        it "should call the retire cellect worker" do
          expect(RetireCellectWorker)
            .to receive(:perform_async)
            .with(sms.subject_id, workflow.id)
          worker.perform(count.id)
        end
      end
    end

    context "sms is not retireable" do
      it 'should not retire subject for the workflow' do
        allow_any_instance_of(SubjectWorkflowStatus).to receive(:retire?).and_return(false)
        worker.perform(count)
        sms.reload
        expect(sms.retired_workflows).to_not include(workflow)
      end
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
    end
  end

  describe "finishing workflows" do
    before do
      allow_any_instance_of(SubjectWorkflowStatus)
        .to receive(:retire?)
        .and_return(true)
    end

    it 'should not mark the workflow as finished when it is not' do
      allow(workflow).to receive(:finished?).and_return(false)
      expect do
        worker.perform(count.id)
      end.to_not change{ Workflow.find(workflow.id).finished_at }
    end

    context "workflow is finished" do
      before do
        allow_any_instance_of(Workflow)
          .to receive(:finished?)
          .and_return(true)
      end

      it 'should set workflow.finished_at to the current time' do
        expect do
          worker.perform(count.id)
        end.to change{ Workflow.find(workflow.id).finished_at }.from(nil)
      end

      context "when the workflow optimistic lock is updated" do
        it 'should save the changes and not raise an error' do
          Workflow.find(workflow.id).touch
          expect { worker.perform(count.id) }.to_not raise_error
        end
      end
    end
  end
end
