require 'spec_helper'

describe Api::V1::SubjectsController, type: :controller do
  let!(:workflow) { create(:workflow_with_subject_sets) }
  let!(:subjects) { create_list(:set_member_subject, 20, subject_set: workflow.subject_sets.first) }
  let!(:user) { create(:user) }

  let(:api_resource_name) { "subjects" }
  let(:api_resource_attributes) do
    [ "id", "metadata", "locations", "zooniverse_id", "created_at", "updated_at"]
  end

  let(:api_resource_links) do
    [ "subjects.owner" ]
  end

  context "logged in user" do
    before(:each) do
      default_request user_id: user.id, scopes: ["subject"]
    end

    describe "#index" do
      context "without random sort" do
        before(:each) do
          get :index
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it "should return a page of 20 objects" do
          expect(json_response[api_resource_name].length).to eq(20)
        end

        it_behaves_like "an api response"
      end

      context "with random sort" do
        let(:api_resource_links) do
          [ "subjects.subject_set" ]
        end

        before(:each) do
          allow(Cellect::Client).to receive(:choose_host).and_return("example.com")
          allow(stubbed_cellect_connection).to receive(:get_subjects)
            .and_return(subjects.take(10).map(&:id))
          request.session = { cellect_hosts: {workflow.id.to_s => 'example.com'} }
          get :index, {sort: 'random', workflow_id: workflow.id.to_s}
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it 'should return a page of 10 objects' do
          expect(json_response[api_resource_name].length).to eq(10)
        end

        it 'should make a request against Cellect' do
          expect(stubbed_cellect_connection).to receive(:get_subjects)
            .with(workflow_id: workflow.id.to_s,
                  user_id: user.id,
                  group_id: nil,
                  host: 'example.com',
                  limit: 10)
            .and_return(subjects.take(10).map(&:id))

          get :index, {sort: 'random', workflow_id: workflow.id.to_s}
        end

        it_behaves_like "an api response"
      end
    end
  end
end
