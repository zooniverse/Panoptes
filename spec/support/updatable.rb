module UpdatableResource
  def self.extract_linked_resource_ids(linked_resource)
    Array.wrap(linked_resource).map { |lr| lr.id.to_s }
  end
end

shared_examples "is updatable" do
  context "an authorized user" do
    let(:updated_resource) { resource.reload }

    before(:each) do
      default_request scopes: scopes, user_id: authorized_user.id
      params = update_params.merge(id: resource.id)
      put :update, params
    end

    it 'should update supplied attributes' do
      field = updated_resource.send(test_attr)
      if field.is_a?(Array)
        expect(field).to match_array(test_attr_value)
      else
        expect(field).to eq(test_attr_value)
      end
    end

    it 'should return 200 and return the updated resource', :aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(json_response[api_resource_name].length).to eq(1)
    end

    it 'should include a Last-Modified header' do
      modified = updated_resource.updated_at.httpdate
      expect(response.headers.to_hash).to include('Last-Modified' => modified)
    end

    it_behaves_like 'an api response'
  end

  context "an unauthorized user" do
    before(:each) do
      user = if defined?(unauthorized_user)
               unauthorized_user
             else
               create(:user)
             end

      default_request scopes: scopes, user_id: user.id
      params = update_params.merge(id: resource.id)
      put :update, params
    end

    it 'should return not found' do
      expect(response).to have_http_status(:not_found)
    end

    it 'should not have modified the resource' do
      expect(resource_class.find(resource.id)).to eq(resource)
    end
  end
end

RSpec.shared_examples "has updatable links" do
  let(:updated_resource) { resource.reload }
  let(:stringified_test_relation_ids) { Array.wrap(test_relation_ids).map(&:to_s) }

  before(:each) do
    default_request scopes: scopes, user_id: authorized_user.id
    params = update_params.merge(id: resource.id)
    put :update, params
  end

  it 'should update any included links' do
    linked_resource = updated_resource.send(test_relation)
    expected_ids = UpdatableResource.extract_linked_resource_ids(linked_resource)
    expect(expected_ids).to include(*stringified_test_relation_ids)
  end
end

RSpec.shared_examples "supports update_links" do
  let!(:old_ids) { resource.send(test_relation).map(&:id) }
  let(:updated_resource) { resource.reload }
  let(:stringified_test_relation_ids) { Array.wrap(test_relation_ids).map(&:to_s) }
  let(:linked_resources) { updated_resource.send(test_relation) }

  before(:each) do
    default_request scopes: scopes, user_id: authorized_user.id
    params = {
      link_relation: test_relation.to_s,
      test_relation => test_relation_ids,
      resource_id => resource.id
    }
    post :update_links, params
  end

  it 'should update any included links' do
    updated_relation_ids = UpdatableResource.extract_linked_resource_ids(linked_resources)
    expect(updated_relation_ids).to include(*stringified_test_relation_ids)
  end

  it 'should retain pre-existing links' do
    expect(linked_resources.map(&:id)).to include(*old_ids)
  end
end


RSpec.shared_examples "supports update_links via a copy of the original" do
  let!(:old_ids) { resource.send(test_relation).map(&:id) }
  let(:updated_resource) { resource.reload }

  let(:update_via_links) do
    default_request scopes: scopes, user_id: authorized_user.id
    params = {
      link_relation: test_relation.to_s,
      test_relation => test_relation_ids,
      resource_id => resource.id
    }
    post :update_links, params
  end

  it 'should have resources to copy' do
    update_via_links
    expect(expected_copies_count).to_not eq(0)
  end

  it 'should be successful' do
    update_via_links
    expect(response).to have_http_status(:ok)
  end

  it "should create a new linked_resource" do
    linked_resource
    expect{ update_via_links }.to change { linked_resource.class.count }.by(1)
  end
end
