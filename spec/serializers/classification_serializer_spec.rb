require 'spec_helper'

describe ClassificationSerializer do
  let(:classification) { create(:classification) }

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { classification }
    let(:includes) { [:project, :user, :user_group, :workflow] }
    let(:preloads) { [:subjects] }
  end

  it_should_behave_like "a no count serializer" do
    let(:resource) { classification }
  end

  describe "nested collection routes" do
    before do
      classification
    end

    it "should return the correct href urls" do
      %w(gold_standard incomplete project).each do |collection_route|
        context = {url_suffix: collection_route}
        result = ClassificationSerializer.page({}, Classification.all, context)
        meta = result[:meta][:classifications]
        expect(meta[:first_href]).to eq("/classifications/#{collection_route}")
        expect(meta[:previous_href]).to eq("/classifications/#{collection_route}?page=0")
        expect(meta[:next_href]).to eq("/classifications/#{collection_route}?page=2")
        expect(meta[:last_href]).to eq("/classifications/#{collection_route}?page=0")
      end
    end

    context "project context with last_id param present" do
      let(:project) { classification.project }

      it "should insert the next hightest last_id into the next_href" do
        second = create(:classification, project: project)
        last_id = classification.id
        params = {project_id: project.id, last_id: last_id, page_size: 1}
        result = ClassificationSerializer.page(params, Classification.all, {})
        meta = result[:meta][:classifications]
        expect(meta[:previous_href]).to eq("/classifications?last_id=#{last_id}&page_size=1&project_id=#{project.id}")
        expect(meta[:next_href]).to eq("/classifications?last_id=#{second.id}&page_size=1&project_id=#{project.id}")
      end
    end
  end
end
