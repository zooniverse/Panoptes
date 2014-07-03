require 'spec_helper'

describe UserGroup, :type => :model do
  let(:user_group) { create(:user_group) }
  let(:activatable) { user_group }
  let(:owner) { user_group }
  let(:owned) { build(:project, owner: owner) }

  it_behaves_like "activatable"
  it_behaves_like "is an owner"

  it "should have a valid factory" do
    expect(build(:user_group)).to be_valid
  end

  describe "#display_name" do

    it 'should validate presence' do
      expect{ UserGroup.create!(display_name: nil) }.to raise_error
    end

    it 'should validate uniqueness' do
      expect{ UserGroup.create!(display_name: "FancyUserGroup") }.to_not raise_error
      expect{ UserGroup.create!(display_name: "FANCYUSERGROUP") }.to raise_error
      expect{ UserGroup.create!(display_name: "fancyusergroup") }.to raise_error
    end

    context "when a user with the same login exists" do
      let!(:user_group) { build(:user_group) }
      let!(:user) { create(:user, login: user_group.display_name) }

      it "should not be valid" do
        expect(user_group.valid?).to be_false
      end

      it "should have the non-uniq display_name error" do
        user_group.valid?
        expect(user_group.errors[:display_name]).to eq('some description of the non-uniq error')
      end
    end
  end

  describe "#users" do
    let(:user_group) { create(:user_group_with_users) }

    it "should have many users" do
      expect(user_group.users).to all( be_a(User) )
    end

    it "should have on user for each membership" do
      ug = user_group
      expect(ug.users.length).to eq(ug.memberships.length)
    end
  end

  describe "#user_group_memberships" do
    let(:user_group) { create(:user_group_with_users) }

    it "should have many user group memberships" do
      expect(user_group.memberships).to all( be_a(Membership) )
    end
  end

  describe "#subjects" do
    let(:relation_instance) { user_group }

    it_behaves_like "it has a subjects association"
  end

  describe "#classifcations_count" do
    let(:relation_instance) { user_group }

    it_behaves_like "it has a cached counter for classifications"
  end
end
