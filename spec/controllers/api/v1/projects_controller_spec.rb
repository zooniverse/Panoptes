require 'spec_helper'

describe Api::V1::ProjectsController, type: :controller do
  let!(:user) {
    create(:user)
  }

  let!(:projects) {
    create_list(:project_with_contents, 2, owner: user)
  }

  let(:api_resource_name) { "projects" }
  let(:api_resource_attributes) do
    [ "id", "name", "display_name", "classifications_count", "subjects_count", "updated_at", "created_at", "available_languages", "content"]
  end
  let(:api_resource_links) do
    [ "projects.owner", "projects.workflows", "projects.subject_sets", "projects.project_contents" ]
  end

  before(:each) do
    default_request(scopes: ["public", "project"], user_id: user.id)
  end

  describe "#index" do

    describe "with no filtering" do

      before(:each) do
        get :index
      end

      it "should return 200" do
        expect(response.status).to eq(200)
      end

      it "should have 2 items by default" do
        expect(json_response[api_resource_name].length).to eq(2)
      end

      it_behaves_like "an api response"
    end

    context "when a project doesn't have any project_contents" do
      let!(:remove_project_contents) do
        Project.first.update_attribute(:project_contents, [])
      end

      it "should have 2 items by default" do
        get :index
        expect(json_response[api_resource_name].length).to eq(2)
      end

      it "should have the first item without any contents" do
        get :index
        expect(json_response[api_resource_name][0]['content']).to eq({})
      end
    end

    describe "filter params" do
      let!(:project_owner) { create(:user) }
      let!(:new_project) do
        create(:project, display_name: "Non-test project", owner: project_owner)
      end

      before(:each) do
        get :index, index_options
      end

      describe "filter by owner" do
        let(:index_options) { { owner: project_owner.name } }

        it "should respond with 1 item" do
          expect(json_response[api_resource_name].length).to eq(1)
        end

        it "should respond with the correct item" do
          owner_id = json_response[api_resource_name][0]['links']['owner']
          expect(owner_id).to eq(new_project.owner.id.to_s)
        end
      end

      describe "filter by display_name" do
        let(:index_options) { { display_name: new_project.display_name } }

        it "should respond with 1 item" do
          expect(json_response[api_resource_name].length).to eq(1)
        end

        it "should respond with the correct item" do
          project_name = json_response[api_resource_name][0]['display_name']
          expect(project_name).to eq(new_project.display_name)
        end
      end

      describe "filter by display_name & owner" do
        let!(:filtered_project) do
          projects.first.update_attribute(:owner_id, project_owner.id)
          projects.first
        end
        let(:index_options) do
          { owner: project_owner.name, display_name: filtered_project.display_name }
        end

        it "should respond with 1 item" do
          expect(json_response[api_resource_name].length).to eq(1)
        end

        it "should respond with the correct item" do
          project_name = json_response[api_resource_name][0]['display_name']
          expect(project_name).to eq(filtered_project.display_name)
        end
      end
    end
  end

  describe "#show" do
    before(:each) do
      get :show, id: projects.first.id
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should return the only requested project" do
      expect(json_response[api_resource_name].length).to eq(1)
      expect(json_response[api_resource_name][0]['id']).to eq(projects.first.id.to_s)
    end

    it_behaves_like "an api response"
  end

  describe "#create" do
    before(:each) do
      params = { display_name: "New Zoo",
                 description: "A new Zoo for you!",
                 name: "new_zoo",
                 primary_language: 'en' }

      post :create, params, { 'CONTENT_TYPE' => 'application/json' }
    end

    it "should create a new project" do
      expect(Project.order(created_at: :desc).first.name).to eq("new_zoo")
    end

    it "should create an associated project_content model" do
      expect(Project.order(created_at: :desc)
              .first.project_contents.first.title).to eq('New Zoo')
      expect(Project.order(created_at: :desc)
              .first.project_contents.first.description).to eq('A new Zoo for you!')
      expect(Project.order(created_at: :desc)
              .first.project_contents.first.language).to eq('en')
    end

    it_behaves_like "an api response"
  end

end
