shared_examples "is creatable" do |action=:create|
  let(:created_id) { created_instance_id(api_resource_name) }

  context "a logged in user" do
    before(:each) do
      default_request scopes: scopes, user_id: authorized_user.id
      post action, create_params
    end

    it "should return created" do
      expect(response).to have_http_status(:created)
    end

    it 'should have an ETag header' do
      expect(response.headers.key?('ETag')).to eq(true)
    end

    it 'should create the new resource' do
      field = resource_class.find(created_id).send(test_attr)

      if field.is_a?(Array)
        expect(field).to match_array(test_attr_value)
      else
        expect(field).to eq(test_attr_value)
      end
    end

    it 'should include a Last-Modified header' do
      updated_at = resource_class.find(created_id).updated_at.httpdate
      expect(response.headers.to_hash).to include('Last-Modified' => updated_at.to_s)
    end

    it "should set the Location header as per JSON-API specs" do
      name = defined?(resource_name) ? resource_name : api_resource_name
      id = created_id
      location_header = response.headers["Location"]
      url = defined?(resource_url) ? resource_url : "http://test.host/api/#{ name }/#{ id }"
      expect(location_header).to match(url)
    end

    it_behaves_like 'an api response'
  end

  context "a non-logged in user" do
    before(:each) do
      default_request
      post action, create_params
    end

    it "should return unauthorized" do
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
