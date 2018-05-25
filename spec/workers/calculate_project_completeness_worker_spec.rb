require 'spec_helper'

describe CalculateProjectCompletenessWorker do
  let(:worker) { described_class.new }
  let(:project) { create :project }

  describe '#project_completeness' do
    it 'returns the average of the workflow completenesses' do
      project = double(active_workflows: [
        double(completeness: 1),
        double(completeness: 0)
      ])

      expect(worker.project_completeness(project)).to eq(0.5)
    end

    context "when it can't find the project" do
      it "should fail quickly" do
        expect(Project).not_to receive(:transaction)
        worker.perform("-1")
      end
    end

    context "when a project has no active workflows" do
      it "should set to 0.0" do
        expect(worker.project_completeness(project)).to eq(0.0)
      end
    end
  end

  describe '#workflow_completeness' do
    let(:subject_set) { create(:subject_set_with_subjects) }
    let(:workflow) do
      create :workflow, subject_sets: [subject_set], retirement: {'criteria' => 'classification_count', 'options' => {'count' => 10}}
    end

    shared_examples "it reports completeness correctly" do

      it 'returns 1 when all the subjects of a workflow have been retired' do
        workflow.classifications_count = 20
        workflow.retired_set_member_subjects_count = 2
        expect(worker.workflow_completeness(workflow)).to eq(1.0)
      end

      it 'returns 0.5 when half of the subjects are retired' do
        workflow.retired_set_member_subjects_count = 1
        expect(worker.workflow_completeness(workflow)).to eq(0.5)
      end

      it 'returns 1.0 when there are more retired subjects than subjects' do
        workflow.retired_set_member_subjects_count = 3
        expect(worker.workflow_completeness(workflow)).to eq(1.0)
      end
    end

    it 'returns 0 when no subjects are linked' do
      allow(workflow).to receive(:subjects_count).and_return(0)
      expect(worker.workflow_completeness(workflow)).to eq(0.0)
    end

    context 'classification count retirement' do
      it_should_behave_like "it reports completeness correctly"
    end

    context 'no panoptes retirement' do
      before do
        workflow.retirement = {'criteria' => 'never_retire', 'options' => {}}
      end

      it_should_behave_like "it reports completeness correctly"
    end
  end

  describe "project state transitions" do
    before do
      allow(Project).to receive(:find).and_return(project)
    end

    context "when the project is not complete" do
      before do
        allow(project)
        .to receive(:active_workflows)
        .and_return([double(completeness: 0.91)])
      end

      it "should not move the project to paused" do
        expect {
          worker.perform(project)
        }.not_to change {
          project.state
        }
      end

      it "should move a paused project to active" do
        project.paused!
        expect {
          worker.perform(project)
        }.to change {
          project.reload.attributes["state"]
        }.to(nil)
      end

      it "should not move an active project to active" do
        expect {
          worker.perform(project)
        }.not_to change {
          project.state
        }
      end

      it "should not move a finished project to active" do
        project.finished!
        expect {
          worker.perform(project)
        }.not_to change {
          project.state
        }
      end
    end

    context "when the project is active and complete" do
      before do
        allow(project)
        .to receive(:active_workflows)
        .and_return([double(completeness: 1)])
      end

      it "should move it to paused" do
        expect {
          worker.perform(project)
        }.to change {
          project.state
        }.to("paused")
      end
    end
  end
end
