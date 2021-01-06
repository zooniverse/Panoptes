RSpec.shared_examples "dump worker" do |mailer_class, dump_type|
  let(:another_project) { create(:project) }

  context "when the project id doesn't correspond to a project" do
    before(:each) do
      allow(Project).to receive(:find).and_return(nil)
    end

    it "should not open a csv file" do
      expect(CSV).to_not receive(:open)
      worker.perform(another_project.id, "project")
    end

    it 'does not push a file to the object store' do
      allow(worker).to receive(:write_to_object_store)
      worker.perform(another_project.id, 'project')
      expect(worker).not_to have_received(:write_to_object_store)
    end

    it "should not queue a worker to send an email" do
      expect(mailer_class).to_not receive(:perform_async)
      worker.perform(another_project.id, "project")
    end
  end

  context "when the project exists" do
    let(:project_file_name) do
      "#{dump_type}_#{project.owner.login}_#{project.display_name.downcase.gsub(/\s/, "_")}.csv"
    end

    it "should create a csv file with the correct number of entries" do
      expect_any_instance_of(CSV).to receive(:<<).exactly(num_entries).times
      worker.perform(project.id, "project")
    end

    it "should queue a worker to send an email" do
      expect(mailer_class).to receive(:perform_async).with(project.id,
                                                           "project",
                                                           anything,
                                                           [project.owner.email])
      worker.perform(project.id, "project")
    end
  end

  context "when a medium id is also provided" do
    let(:receivers) { create_list(:user, 2) }
    let(:metadata) { { "recipients" => receivers.map(&:id) } }
    let(:medium) do
      create(:medium,
             metadata: metadata,
             linked: project,
             content_type: "text/csv",
             type: dump_type)
    end

    it 'should email the users in the recipients hash' do
      expect(mailer_class).to receive(:perform_async)
        .with(anything, "project", anything, array_including(receivers.map(&:email)))
      worker.perform(project.id, "project", medium.id)
    end

    context "Dump workers are disabled" do
      before { Panoptes.flipper[:dump_worker_exports].disable }

      it "raises an exception" do
        expect { worker.perform(project.id, "project", medium.id) }.to raise_error(ApiErrors::FeatureDisabled)
      end
    end
  end
end
