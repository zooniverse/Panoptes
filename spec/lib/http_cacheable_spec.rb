require 'spec_helper'

describe HttpCacheable do
  let(:resource_name) { controlled_resources.klass.model_name }
  let(:resource) do
    factory_name = resource_name.singular.to_sym
    create(factory_name)
  end
  let(:http_cache) do
    HttpCacheable.new(controlled_resources)
  end

  def make_private(public_resource)
    public_resource.update_column(:private, true)
  end

  before do
    Panoptes.flipper["http_caching"].enable
    resource
  end

  describe '#cacheable?' do
    context "when http caching is disabled" do
      let(:controlled_resources) { Project.all }

      it "should return false for a public resource" do
        Panoptes.flipper["http_caching"].disable
        expect(http_cache.cacheable?).to be false
      end
    end

    describe "a non-cacheable resource" do
      let(:controlled_resources) { Collection.all }

      it "should return false for a public resource" do
        expect(http_cache.cacheable?).to be false
      end

      it "should return false for a private resource" do
        make_private(resource)
        expect(http_cache.cacheable?).to be false
      end
    end

    describe "parental controlled resources" do
      [ Subject, Workflow ].each do |resource_klass|
        let(:controlled_resources) { resource_klass.all }

        it "should return true with a public resource" do
          expect(http_cache.cacheable?).to be true
        end

        it "should return false with a private resource" do
          parent_relation = :project
          parent_resource = resource.send(parent_relation)
          make_private(parent_resource)
          expect(http_cache.cacheable?).to be false
        end
      end
    end

    describe "controlled resources" do
      let(:controlled_resources) { Project.all }

      it "should return true with a public resource" do
        expect(http_cache.cacheable?).to be true
      end

      it "should return false with a private resource" do
        make_private(resource)
        expect(http_cache.cacheable?).to be false
      end
    end
  end

  describe "#resource_cache_directive" do
    context "with a non-cacheable resource" do
      let(:controlled_resources) { Collection.all }

      it "should response with nil if not cacheable" do
        expect(http_cache.resource_cache_directive).to be_nil
      end
    end

    context "with a cacheable resource" do
      [ Project, Subject, Workflow ].each do |resource_klass|
        let(:controlled_resources) { resource_klass.all }
        let(:cache_directive) { "public, max-age=60" }

        it "should response with the correct cache directive" do
          expect(http_cache.resource_cache_directive).to eq(cache_directive)
        end

        context "with feature flag to ensure private browser caching" do
          let(:cache_directive) { "private max-age: 60" }

          it "should not allow public caching" do
            Panoptes.flipper[:private_http_caching].enable
            expect(http_cache.resource_cache_directive).to eq(cache_directive)
          end
        end
      end
    end
  end
end
