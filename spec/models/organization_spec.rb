require 'spec_helper'

describe Organization, type: :model do
  let(:organization) { build(:organization) }

  it_behaves_like "is ownable" do
    let(:owned) { organization }
    let(:not_owned) { build(:organization, owner: nil) }
  end

  it_behaves_like "activatable" do
    let(:activatable) { organization }
  end

  it_behaves_like "is translatable" do
    let(:translatable) { create(:organization) }
    let(:translatable_without_content) { build(:organization, build_contents: false) }
    let(:primary_language_factory) { :organization }
    let(:private_model) { create(:organization, listed_at: nil) }
  end

  it "should have a valid factory" do
    expect(organization).to be_valid
  end

  it "should require a primary language field to be set" do
    expect(build(:organization, primary_language: nil)).to_not be_valid
  end

  it_behaves_like "has slugged name"

  describe "#organization_roles" do
    let!(:preferences) do
      [create(:access_control_list, resource: organization, roles: []),
       create(:access_control_list, resource: organization, roles: ["tester"]),
       create(:access_control_list, resource: organization, roles: ["collaborator"])]
    end

    it 'should include models with assigned roles' do
      expect(organization.organization_roles).to include(*preferences[1..-1])
    end

    it 'should not include models without assigned roles' do
      expect(organization.organization_roles).to_not include(preferences[0])
    end
  end

  describe '#retired_subjects_count' do
    it 'counts across active workflows' do
      project1 = create :project, organization: organization
      workflow1 = create(:workflow, project: project1, retired_set_member_subjects_count: 4)
      workflow2 = create(:workflow, project: project1, retired_set_member_subjects_count: 2)
      expect(organization.retired_subjects_count).to eq(6)
    end
  end
end
