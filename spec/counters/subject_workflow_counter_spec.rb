require 'spec_helper'

describe SubjectWorkflowCounter do
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:sws) do
    create(:subject_workflow_status, workflow: workflow, classifications_count: 0)
  end
  let(:counter) { SubjectWorkflowCounter.new(sws) }

  describe 'classifications' do
    let(:now) { DateTime.now.utc }

    it "should return 0 if there are none" do
      expect(counter.classifications).to eq(0)
    end

    context "with classifications" do
      let(:classifications) do
        create_list(
          :classification,
          2,
          subject_ids: [sws.subject_id],
          project: project,
          workflow: workflow
        )
      end
      before do
        classifications
      end

      it "should return 2" do
        expect(counter.classifications).to eq(2)
      end

      it "should respect the project launch date" do
        allow(project).to receive(:launch_date).and_return(now)
        expect(counter.classifications).to eq(0)
        allow(project).to receive(:launch_date).and_return(now-1.day)
        expect(counter.classifications).to eq(2)
      end

      context "with classifications that do not count", :disabled do
        let(:default_attrs) do
          {
            subject_ids: [sws.subject_id],
            project: project,
            workflow: workflow,
            user: project.owner
          }
        end
        def create_non_counting_classification(attrs)
          create(:classification, default_attrs.merge(attrs))
        end

        it "should ignore any incomplete classifications" do
          create_non_counting_classification(completed: false)
          expect(counter.classifications).to eq(2)
        end

        it "should ignore any gold standard classifications" do
          create_non_counting_classification(gold_standard: true)
          expect(counter.classifications).to eq(2)
        end

        it "should ignore any already seens classifications" do
          metadata = classifications.first.metadata
          metadata[:seen_before] = true
          create_non_counting_classification(metadata: metadata)
          expect(counter.classifications).to eq(2)
        end
      end

      context "when the subject is classified for other workflows" do
        let(:another_workflow) { create(:workflow, project: project) }

        it "should still only count 2" do
          create(:classification, subject_ids: [sws.subject_id], project: project, workflow: another_workflow)
          expect(counter.classifications).to eq(2)
        end
      end
    end
  end
end
