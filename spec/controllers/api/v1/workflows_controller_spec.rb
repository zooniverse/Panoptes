require 'spec_helper'

describe Api::V1::WorkflowsController, type: :controller do
  let(:user) { create(:user) }
  let(:workflows) { create_list :workflow_with_contents, 2 }
  let(:workflow){ workflows.first }
  let(:project){ workflow.project }
  let(:owner){ project.owner }
  let(:api_resource_name){ 'workflows' }
  let(:resource_class) { Workflow }
  let(:authorized_user) { owner }

  let(:api_resource_attributes) do
    %w(id display_name tasks classifications_count subjects_count created_at updated_at first_task primary_language content_language version grouped prioritized pairwise retirement)
  end
  let(:api_resource_links){ %w(workflows.project workflows.subject_sets workflows.tutorial_subject workflows.expert_subject_set) }
  let(:scopes) { %w(public project) }

  before(:each) do
    PaperTrail.enabled = true
    PaperTrail.enabled_for_controller = true
  end

  after(:each) do
    PaperTrail.enabled = false
    PaperTrail.enabled_for_controller = false
  end

  describe '#index' do
    let(:filterable_resources) { create_list(:workflow_with_subjects, 2) }
    let(:expected_filtered_ids) { [ filterable_resources.first.id.to_s ] }
    let(:private_project) { create(:private_project) }
    let!(:private_resource) { create(:workflow, project: private_project) }
    let(:n_visible) { 2 }

    it_behaves_like 'is indexable'
    it_behaves_like 'has many filterable', :subject_sets
  end

  describe '#update' do
    let(:subject_set) { create(:subject_set, project: project) }
    let(:resource) { create(:workflow_with_contents, project: project) }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { "A Better Name" }
    let(:test_relation) { :subject_sets }
    let(:test_relation_ids) { subject_set.id.to_s }
    let(:resource_id) { :workflow_id }
    let(:update_params) do
      {
       workflows: {
                   display_name: "A Better Name",
                   retirement: {
                                criteria: "classification_count"
                               },
                   tasks: {
                           interest: {
                                      type: "draw",
                                      question: "Draw a Circle",
                                      next: "shape",
                                      tools: [
                                              {value: "red", label: "Red", type: 'point', color: 'red'},
                                              {value: "green", label: "Green", type: 'point', color: 'lime'},
                                              {value: "blue", label: "Blue", type: 'point', color: 'blue'},
                                             ]
                                     }
                          },
                   links: {
                           subject_sets: [subject_set.id.to_s],
                          }

                  }
      }
    end

    it_behaves_like "is updatable"

    it_behaves_like "has updatable links"

    context "extracts strings from workflow" do
      it 'should replace "Draw a circle" with 0' do
        default_request scopes: scopes, user_id: authorized_user.id
        put :update, update_params.merge(id: resource.id)
        instance = Workflow.find(created_instance_id(api_resource_name))
        expect(instance.tasks["interest"]["question"]).to eq("interest.question")
      end
    end

    context "with authorized user" do
      context "when the workflow has subjects" do
        let(:subject_set) { create(:subject_set_with_subjects, project: resource.project) }

        it 'should call the reload queue worker' do
          expect(ReloadQueueWorker).to receive(:perform_async).with(resource.id)
          default_request scopes: scopes, user_id: authorized_user.id
          put :update, update_params.merge(id: resource.id)
        end
      end

      context "when the workflow has no subjects" do
        it "should not queue the worker" do
          expect(ReloadQueueWorker).to_not receive(:perform_async).with(resource.id)
          default_request scopes: scopes, user_id: authorized_user.id
          put :update, update_params.merge(id: resource.id)
        end
      end
    end

    context "without authorized user" do
      it 'should not call the reload queue worker' do
        expect(ReloadQueueWorker).to_not receive(:perform_async).with(resource.id)
        default_request scopes: scopes, user_id: create(:user).id
        put :update, update_params.merge(id: resource.id)
      end
    end
  end

  describe "#update_links" do
    let(:subject_set_project) { project }
    let(:linked_resource) { create(:subject_set_with_subjects, project: subject_set_project) }
    let(:test_attr) { :display_name }
    let(:test_relation) { :subject_sets }
    let(:test_relation_ids) { [ linked_resource.id.to_s ] }
    let(:expected_copies_count) { linked_resource.subjects.count }
    let(:resource) { workflow }
    let(:resource_id) { :workflow_id }
    let(:copied_resource) { resource.reload.send(test_relation).first }

    it_behaves_like "supports update_links"

    context "when the subject_set links belong to another project" do
      let!(:subject_set_project) do
        workflows.find { |w| w.project != project }.project
      end

      it_behaves_like "supports update_links via a copy of the original" do

        it 'should have the same name' do
          update_via_links
          expect(copied_resource.display_name).to eq(linked_resource.display_name)
        end

        it 'should belong to the correct project' do
          update_via_links
          expect(copied_resource.project_id).to eq(resource.project_id)
        end

        it 'should create copies of every subject via set_member_subjects' do
          expect{ update_via_links }.to change { SetMemberSubject.count }.by(expected_copies_count)
        end
      end
    end
  end

  describe '#create' do
    let(:test_attr) { :display_name }
    let(:test_attr_value) { 'Test workflow' }
    let(:create_params) do
      {
       workflows: {
                   display_name: 'Test workflow',
                   first_task: 'interest',
                   retirement: {
                                criteria: "classification_count"
                               },
                   tasks: {
                           interest: {
                                      type: "draw",
                                      question: "Draw a Circle",
                                      next: "shape",
                                      tools: [
                                              {value: "red", label: "Red", type: 'point', color: 'red'},
                                              {value: "green", label: "Green", type: 'point', color: 'lime'},
                                              {value: "blue", label: "Blue", type: 'point', color: 'blue'},
                                             ]
                                     },
                           shape: {
                                   type: 'multiple',
                                   question: "What shape is this galaxy?",
                                   answers: [
                                             {value: 'smooth', label: "Smooth"},
                                             {value: 'features', label: "Features"},
                                             {value: 'other', label: 'Star or artifact'}
                                            ],
                                   next: nil
                                  }
                          },
                   grouped: true,
                   prioritized: true,
                   primary_language: 'en',
                   links: {
                           project: project.id.to_s
                          }
                  }
      }
    end

    context "when the linked project is owned by a user" do
      it_behaves_like "is creatable"
    end

    context "when a project is owned by a user group" do
      let(:membership) { create(:membership, state: 0, roles: ["project_editor"]) }
      let(:project) { create(:project, owner: membership.user_group) }
      let(:authorized_user) { membership.user }

      it_behaves_like "is creatable"
    end

    context "extracts strings from workflow" do
      it 'should replace "Draw a circle" with 0' do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
        instance = Workflow.find(created_instance_id(api_resource_name))
        expect(instance.tasks["interest"]["question"]).to eq("interest.question")
      end
    end

    context "includes a tutorial subject" do
      let(:tut_sub) { create(:subject, project: project).id.to_s }

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        create_params[:workflows][:links][:tutorial_subject] = tut_sub
        post :create, create_params
      end

      it 'responds with tutorial subject link' do
        expect(json_response['workflows'][0]['links']['tutorial_subject']).to eq(tut_sub)
      end

      it 'responds with a tutorial subject link template' do
        expect(json_response['links']['workflows.tutorial_subject']['href']).to eq("/subjects/{workflows.tutorial_subject}")
      end
    end

    context "when the project is live" do
      before(:each) do
        allow_any_instance_of(Project).to receive(:live).and_return(true)
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
      end

      it 'returns forbidden with a useful error' do
        aggregate_failures "status and error" do
          expect(response).to be_forbidden
          msg = "Can't create a workflow for a live project."
          expect(response.body).to eq(json_error_message(msg))
        end
      end
    end
  end

  describe '#destroy' do
    let(:resource) { workflow }

    it_behaves_like "is destructable"
  end

  describe "#show" do
    let(:resource) { workflows.first }

    it_behaves_like "is showable"

    context "with a logged in user" do
      it "should load a user's subject queue" do
        expect(SubjectQueueWorker).to receive(:perform_async).with(resource.id.to_s, authorized_user.id)
        default_request scopes: scopes, user_id: authorized_user.id
        get :show, id: resource.id
      end
    end

    context "with a logged out user" do
      it "should load the general subject queue" do
        expect(SubjectQueueWorker).to receive(:perform_async).with(resource.id.to_s, nil)
        get :show, id: resource.id
      end
    end
  end

  describe '#retire_subject' do
    let(:subject_id) { "1" }
    let(:workflow_id) { "2" }

    context "with authorized user" do
      it 'should call the subject retirement worker' do
        expect(SubjectRetirementWorker).to receive(:perform_async).with(subject_id, workflow_id)
        default_request scopes: scopes, user_id: authorized_user.id
        post :retire_subject, subject_id: subject_id, id: workflow_id
      end
    end

    context "without authorized user" do
      it 'should not call the subject retirement worker' do
        expect(SubjectRetirementWorker).to_not receive(:perform_async).with(subject_id, workflow_id)
        default_request scopes: scopes, user_id: create(:user).id
        post :retire_subject, subject_id: subject_id, id: workflow_id
      end
    end
  end

  describe "versioning" do
    let(:resource) { workflow }
    let!(:existing_versions) { resource.versions.length }
    let(:num_times) { 11 }
    let(:update_proc) { Proc.new { |resource, n| resource.update!(prioritized: (n % 2 == 0)) } }
    let(:resource_param) { :workflow_id }

    it_behaves_like "a versioned resource"
  end
end
