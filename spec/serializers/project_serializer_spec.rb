require 'spec_helper'

describe ProjectSerializer do
  let(:project) { create(:full_project, state: "finished", live: false) }
  let(:context) { {languages: ['en'], fields: [:title, :url_labels]} }

  let(:serializer) do
    s = ProjectSerializer.new
    s.instance_variable_set(:@model, project)
    s.instance_variable_set(:@context, context)
    s
  end

  it "should not preload the serialized associations by default" do
    expect_any_instance_of(Project::ActiveRecord_Relation).not_to receive(:preload)
    ProjectSerializer.page({}, Project.all, {})
  end

  it "should preload the serialized associations if enabled" do
    allow_any_instance_of(CodeExperiment).to receive(:enabled?).and_return(true)
    Panoptes.flipper["eager_load_projects"].enable
    expect_any_instance_of(Project::ActiveRecord_Relation)
      .to receive(:preload)
      .with(*ProjectSerializer::PRELOADS)
      .and_call_original
    ProjectSerializer.page({}, Project.all, {})
  end

  describe "#content" do
    it "should return project content for the preferred language" do
      expect(serializer.content).to be_a( Hash )
      expect(serializer.content).to include(:title)
    end
  end

  describe "#urls" do
    it "should return the translated version of the url labels" do
      urls = [{"label" => "Blog",
               "url" => "http://blog.example.com/"},
              {"label" => "Twitter",
               "url" => "http://twitter.com/example"}]
      expect(serializer.urls).to eq(urls)
    end
  end

  describe "#state" do
    it "includes the state" do
      expect(serializer.state).to eq project.state
    end

    describe 'can filter by state' do
      let(:paused_live_project) { create(:full_project, state: "paused", live: true) }
      let(:paused_project) { create(:full_project, state: "paused", live: false) }
      let(:live_project) { create(:full_project, state: nil, live: true) }

      before do
        live_project.save
        paused_project.save
        project.save
      end

      it 'includes filtered projects' do
        results = described_class.page({"state" => "paused"}, Project)
        expect(results[:projects].map { |p| p[:id] }).to include(paused_project.id.to_s)
        expect(results[:projects].count).to eq(1)
      end

      it 'includes non-enum states' do
        results = described_class.page({"state" => "live"}, Project)
        expect(results[:projects].map { |p| p[:id] }).to include(live_project.id.to_s)
        expect(results[:projects].count).to eq(1)
      end

      it 'does not include projects with a state, even if live' do
        results = described_class.page({"state" => "live"}, Project)
        expect(results[:projects].map { |p| p[:id] }).not_to include(paused_live_project.id.to_s)
        expect(results[:projects].map { |p| p[:id] }).not_to include(paused_project.id.to_s)
      end
    end
  end

  describe "#avatar_src" do
    let(:avatar) { double("avatar", external_link: external_url, src: src) }
    let(:src) { nil }
    let(:external_url) { nil }

    context "without external" do
      let(:src) { "http://subject1.zooniverse.org" }

      it "should return the src by default" do
        allow(project).to receive(:avatar).and_return(avatar)
        expect(serializer.avatar_src).to eq(src)
      end
    end

    context "with an external url" do
      let(:external_url) { "http://test.example.com" }

      it "should return the external src if set" do
        allow(project).to receive(:avatar).and_return(avatar)
        expect(serializer.avatar_src).to eq(external_url)
      end
    end
  end

  describe "media links" do
    let(:links) { [:attached_images, :avatar, :background] }
    let(:serialized) { ProjectSerializer.resource({}, Project.where(id: project.id), context) }

    it 'should include top level links for media' do
      expect(serialized[:links]).to include(*links.map{ |l| "projects.#{l}" })
    end

    it 'should include resource level links for media' do
      expect(serialized[:projects][0][:links]).to include(*links)
    end

    it 'should include hrefs for links' do
      serialized[:projects][0][:links].slice(*links).each do |_, linked|
        expect(linked).to include(:href)
      end
    end

    it 'should include the id for single links' do
      serialized[:projects][0][:links].slice(:avatar, :background).each do |_, linked|
        expect(linked).to include(:id)
      end
    end
  end
end
