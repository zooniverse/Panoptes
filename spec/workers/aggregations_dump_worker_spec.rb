require "spec_helper"

RSpec.describe AggregationsDumpWorker do

  let(:agg_double) {double(aggregate: nil)}

  before(:each) do
    Panoptes.flipper[:dump_worker_exports].enable
    allow(AggregationClient).to receive(:new).and_return(agg_double)
  end

  let!(:project) { create(:project) }
  let!(:medium) { create(:medium, type: "project_aggregations_export", content_type: "application/x-gzip") }

  subject { described_class.new }

  it 'should create a medium with put_expires equal to one day in seconds' do
    expect do
      subject.perform(project, "project", medium)
      medium.reload
    end.to change{medium.put_expires}.from(nil).to(86400)
  end

  it 'should send an aggregate message to the AggregationClient' do
    expect(agg_double).to receive(:aggregate)
    subject.perform(project, "project", medium)
  end

  context "Dump workers are disabled" do
    before { Panoptes.flipper[:dump_worker_exports].disable }

    it "raises an exception" do
      expect { subject.perform(project, "project", medium) }.to raise_error(ApiErrors::ExportDisabled)
    end
  end
end
