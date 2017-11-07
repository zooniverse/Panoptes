require 'spec_helper'

RSpec.describe ClassificationsDumpWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:subject) { create(:subject, project: project, subject_sets: [create(:subject_set, workflows: [workflow])]) }
  let(:classifications) do
    create_list(:classification, 2, project: project, workflow: workflow, subjects: [subject])
  end
  let(:classification_row_exports) do
    classifications.map do |c|
      ClassificationExportRow.create_from_classification(c)
    end
  end

  describe "#perform" do
    let(:num_entries) { classifications.size + 1 }
    it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export"

    context "with read slave enable" do
      before do
        Panoptes.flipper["dump_data_from_read_slave"].enable
      end

      it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export"
    end

    context "with export row strategy dumper enabled" do
      let(:num_entries) { classification_row_exports.size + 1 }

      before do
        Panoptes.flipper["dump_classifications_csv_using_export_rows"].enable
      end

      it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export"

      context "with the export row backfill enabled" do
        let(:num_entries) { classifications.size + 1 }

        before do
          Panoptes.flipper["dump_backfill_classification_export_rows"].enable
        end

        it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export"
      end
    end

    context "with multi subject classification" do
      let(:second_subject) { create(:subject, project: project, subject_sets: subject.subject_sets) }
      let(:classifications) do
        [ create(:classification, project: project, workflow: workflow, subjects: [subject, second_subject]) ]
      end
      let(:num_entries) { classifications.size + 1 }

      it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export"
    end
  end
end
