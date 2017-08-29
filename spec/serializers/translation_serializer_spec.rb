require 'spec_helper'

describe TranslationSerializer do
  let(:translation) { create(:translation) }

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { translation }
    let(:includes) { [] }
    let(:preloads) { [] }
  end

  describe "filtering" do
    before do
      translation
    end
    let(:serialized_result) { described_class.page(filter, Translation.all) }
    let(:filtered_resources) { serialized_result[:translations] }
    let(:filtered_ids) { filtered_resources.map { |p| p[:id] } }

    context "language" do
      let(:lang_code) { "en-AU"}
      let(:filtered_translation) { create(:translation, language: lang_code) }
      let(:filter) { { language: lang_code } }

      it "should filter on language codes" do
        filtered_translation
        expect(filtered_ids).to match_array([filtered_translation.id.to_s])
        expect(filtered_resources.count).to eq(1)
      end
    end
  end

  describe "translation links" do
    let(:serialized_result) do
      described_class.send(
        serialize_method,
        {},
        Translation.where(id: translation.id),
        {}
      )
    end
    let(:result_links) { serialized_result.fetch(:links, {}) }

    # for each translated resource type
    [Project].each do |klass|

      describe "top level links" do
        let(:serialize_method) { :resource }
        let(:expected_links) do
          model_name = klass.model_name.singular
          route_key = klass.model_name.route_key
          {
            "translations.#{model_name}" => {
              href: "/#{route_key}/{translations.#{model_name}}",
              type: klass.model_name.plural.to_sym
            }
          }
        end

        it "should include top level links for translated resources" do
          expect(serialized_result.key?(:links)).to be true
          expect(result_links).to match_array(expected_links)
        end
      end

      describe "resource links" do
        let(:expected_links) do
          { klass.model_name.singular.to_sym => translation.translated_id.to_s }
        end

        context "with a serialized resource" do
          let(:serialize_method) { :single }

          it "should include resource links for the polymorphic translated association" do
            expect(serialized_result.key?(:links)).to be true
            expect(result_links).to eq(expected_links)
          end
        end
      end
    end
  end
end
