require 'spec_helper'

describe CollectionSerializer do
  let(:collection) { create(:collection_with_subjects) }

  describe "::btm_associations" do
    it "should be overriden" do
      expected = [ Collection.reflect_on_association(:projects) ]
      expect(CollectionSerializer.btm_associations).to match_array(expected)
    end
  end

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { collection }
    let(:includes) { [ :owner, :collection_roles, :subjects ] }
    let(:preloads) do
      [ [ owner: { identity_membership: :user } ], :collection_roles, :subjects ]
    end
  end

  it_should_behave_like "a filter has many serializer" do
    let(:resource) { create(:collection_with_subjects) }
    let(:relation) { :subjects }
    let(:next_page_resource) do
      create(:collection, subjects: resource.subjects)
    end
  end

  describe "sorting" do
    before do
      collection
      first_by_name
    end

    let(:first_by_name) do
      create(:collection, build_projects: false, display_name: "Aardvarks")
    end
    let(:serialized_page) do
      CollectionSerializer.page({sort: "display_name"}, Collection.all, {})
    end

    describe "by display_name" do
      it 'should respect the sort order query param' do
        results = serialized_page[:collections].map{ |r| r[:display_name] }
        expected = [ first_by_name.display_name, collection.display_name ]
        expect(results).to eq(expected)
      end
    end
  end
end
