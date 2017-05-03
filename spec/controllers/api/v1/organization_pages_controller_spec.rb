require "spec_helper"

describe Api::V1::OrganizationPagesController, type: :controller do
  let(:organization) { create(:organization) }
  let!(:pages) do
    [create(:organization_page, organization: organization),
     create(:organization_page, organization: organization, url_key: "faq"),
     create(:organization_page, organization: organization, language: 'zh-tw'),
     create(:organization_page)]
  end

  let(:scopes) { %w(public organization) }

  let(:api_resource_name) { "organization_pages" }
  let(:api_resource_attributes) do
    ["title", "created_at", "updated_at", "type", "content", "language", "url_key"]
  end

  let(:api_resource_links) { ["organization_pages.organization"] }

  let(:authorized_user) { organization.owner }

  let(:resource) { pages.first }
  let(:resource_class) { OrganizationPage }

  describe "#index" do
    let(:index_params) { {organization_id: organization.id} }
    let(:n_visible) { 2 }

    it_behaves_like "is indexable", false

    describe "filter options" do
      let(:filter_opts) { {} }
      let(:headers) { {} }
      before(:each) do
        index_params.merge!(filter_opts)
        default_request scopes: scopes, user_id: authorized_user.id
        request.env.merge!(headers)
        get :index, index_params
      end

      describe "filter by url_key" do
        let(:filter_opts) { {url_key: "science_case"} }

        it 'should return matching pages' do
          expect(json_response[api_resource_name].map{ |p| p['url_key'] }).to all( eq("science_case") )
        end
      end

      describe "filter by language", :disabled do
        context "as a query param" do
          let(:filter_opts) { {language: "zh-tw"} }

          it 'should return matching pages' do
            expect(json_response[api_resource_name].map{ |p| p['language'] }).to all( eq("zh-tw") )
          end
        end

        context "using the Accept-Language Header" do
          let(:headers) { {"HTTP_ACCEPT_LANGUAGE" => "zh-tw"} }

          it 'should return matching pages' do
            expect(json_response[api_resource_name].map{ |p| p['language'] }).to all( eq("zh-tw") )
          end
        end

        context "when language is all" do
          let(:filter_opts) { {language: "all" } }

          it 'should not filter by language at all' do
            expect(json_response[api_resource_name].length).to eq(3)
          end
        end
      end
    end

    describe "paging" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        get :index, index_params
      end

      it 'should use correct paging links' do
        expect(json_response["meta"][api_resource_name]["first_href"]).to match(%r{organizations/[0-9]+/pages})
      end
    end
  end

  describe "#show" do
    let(:show_params) { {organization_id: organization.id} }

    it_behaves_like "is showable"
  end

  describe "#create" do
    let(:test_attr) { :content }
    let(:test_attr_value) { "dancer" }
    let(:resource_url) { "http://test.host/api/organizations/#{organization.id}/pages/#{created_id}"}
    let(:create_params) do
      {
       organization_id: organization.id,
       organization_pages: {
                       content: "dancer",
                       url_key: "whatevs",
                       language: "en-CA",
                       title: "Bester Pager"
                      }
      }
    end

    it_behaves_like "is creatable"

    it 'should set organization from the organization_id param' do
      default_request scopes: scopes, user_id: authorized_user.id
      post :create, create_params
      expect(json_response[api_resource_name][0]["links"]["organization"]).to eq(organization.id.to_s)
    end
  end

  describe "#update" do
    let(:test_attr) { :content }
    let(:test_attr_value) { "dancer" }
    let(:update_params) do
      {
       organization_id: organization.id,
       organization_pages: {
                       content: "dancer"
                      }
      }
    end

    it_behaves_like "is updatable"
  end

  describe "#destroy" do
    let(:delete_params) { {organization_id: organization.id} }

    it_behaves_like "is destructable"
  end
end
