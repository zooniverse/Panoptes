require 'spec_helper'

describe User, type: :model do
  let(:user) { create(:user) }
  let(:activatable) { user }
  let(:owner) { user }
  let(:owned) { create(:project, owner: user.identity_group) }

  it_behaves_like "activatable"
  it_behaves_like "is an owner"

  context "with caching resource associations" do
    let(:cached_resource) { user }

    it_behaves_like "has an extended cache key" do
      let(:methods) { %i(uploaded_subjects_count) }
    end
  end

  describe '::subset_selection' do
    it "should find users with ids ending in 5 only" do
      unselected_user = create(:user, id: 37)
      selected_user = create(:user, id: 35)
      expect(User.subset_selection).to match_array([selected_user])
    end
  end

  describe '::dormant' do
    let(:user) { create(:user) }

    def dormant_user_ids(num_days_since_activity=5)
      [].tap do |user_ids|
        User.dormant(num_days_since_activity) do |dormant_user|
          user_ids << dormant_user.id
        end
      end
    end

    before { user }

    it "should not find any users that have not signed in" do
      expect(dormant_user_ids).to match_array([])
    end

    context "with a login 5 days ago" do
      let(:user) do
        create(:user, current_sign_in_at: 5.days.ago)
      end

      it "should find users with a valid email" do
        invalid = create(:user, valid_email: false, current_sign_in_at: 5.days.ago)
        expect(dormant_user_ids).to match_array([user.id])
      end

      it "should find users who have opted in to zooniverse emails" do
        opt_out = create(:user, global_email_communication: false, current_sign_in_at: 5.days.ago)
        expect(dormant_user_ids).to match_array([user.id])
      end

      it "should find active users" do
        inactive = create(:inactive_user, current_sign_in_at: 5.days.ago)
          expect(dormant_user_ids).to match_array([user.id])
      end

      it "should find the dormant user" do
        expect(dormant_user_ids).to match_array([user.id])
      end

      it "should not find the dormant user with 6 days gap between signin" do
        expect(dormant_user_ids(6)).to match_array([])
      end

      context "with lifecycled classifications", sidekiq: :inline do
        let(:classification) do
          create(:classification, user: user, created_at: days_ago)
        end

        before do
          ClassificationLifecycle.perform(classification, "create")
          upp = UserProjectPreference.where(
            user_id: user.id,
            project_id: classification.project_id
          ).first
          upp.update_column(:updated_at, days_ago)
        end

        context "user last classified 14 days ago" do
          let(:days_ago) { 14.days.ago}

          it "should return the user" do
            expect(dormant_user_ids).to match_array([user.id])
          end

          it "should handle window period string params" do
            expect(dormant_user_ids("5")).to match_array([user.id])
          end
        end

        context "user last classified 2 days ago" do
          let(:days_ago) { 2.days.ago}

          it "should not return the user" do
            expect(dormant_user_ids).to match_array([])
          end
        end
      end
    end

    context "multiple users: 2 dormant, 1 not" do
      let(:user) do
        create(:user, current_sign_in_at: 12.months.ago)
      end
      let(:another_user) do
        create(:user, current_sign_in_at: 30.days.ago)
      end
      let(:non_dormant_user) do
        create(:user, current_sign_in_at: 1.day.ago)
      end

      it "should find dormant users" do
        non_dormant_user
        expected_ids = [ user.id, another_user.id ]
        expect(dormant_user_ids).to match_array(expected_ids)
      end

      it "should find only one dormant user with 31 day gap between signin" do
        expect(dormant_user_ids(31)).to match_array([user.id])
      end

      it "should find the all the dormant users with 1 day gap between signin" do
        expected_ids = [ user.id, another_user.id, non_dormant_user.id ]
        expect(dormant_user_ids(1)).to match_array(expected_ids)
      end
    end
  end

  describe "::user_from_unsubscribe_token" do

    it "should find the user from the token" do
      found_user = User.user_from_unsubscribe_token(user.unsubscribe_token)
      expect(found_user.id).to eq(user.id)
    end

    it "should not return a user for a non-matching signature" do
      expect(User.user_from_unsubscribe_token("bluirhkj")).to be_nil
    end
  end

  describe '::send_reset_password_instructions' do
    context 'when the user exists' do
      let(:user) { create(:user) }

      it 'sends a password reset' do
        expect_any_instance_of(User).to receive(:send_reset_password_instructions).once
        User.send_reset_password_instructions(email: user.email)
      end

      it 'returns the user' do
        returned_user = User.send_reset_password_instructions(email: user.email)
        expect(returned_user).to eq(user)
      end
    end

    context 'when the user is disabled' do
      let(:user) { create(:user).tap(&:disable!) }

      it 'does not send a password reset' do
        expect_any_instance_of(User).to receive(:send_reset_password_instructions).never
        User.send_reset_password_instructions(email: user.email)
      end

      it 'returns the user' do
        returned_user = User.send_reset_password_instructions(email: user.email)
        expect(returned_user).to eq(user)
      end
    end

    context 'when the user has no email' do
      let(:user) { build(:user, email: nil) }

      it 'does not send a password reset' do
        expect_any_instance_of(User).to receive(:send_reset_password_instructions).never
        User.send_reset_password_instructions(email: user.email)
      end

      it 'returns an unpersisted user' do
        returned_user = User.send_reset_password_instructions(email: user.email)
        expect(returned_user).not_to be_persisted
      end
    end

    context 'when the user cannot be found' do
      it 'does not send a password reset' do
        expect_any_instance_of(User).to receive(:send_reset_password_instructions).never
        User.send_reset_password_instructions(email: 'unknown@example.com')
      end

      it 'returns an unpersisted user' do
        returned_user = User.send_reset_password_instructions(email: 'unknown@example.com')
        expect(returned_user).not_to be_persisted
      end
    end
  end

  describe "::find_by_lower_login" do

    it "should find the user by the login" do
      user = create(:user)
      expect(User.find_by_lower_login(user.login.upcase).id).to eq(user.id)
    end

    context "when no user exits" do
      it "should not find the user by the login" do
        expect(User.find_by_lower_login("missing-User")).to be_nil
      end
    end
  end

  describe "#signup_project" do
    let(:project) { create(:project) }

    it "should not find any associated project" do
      expect(user.signup_project).to be_nil
    end

    context "when the project_id is set" do
      let!(:user) { create(:user, project_id: project.id) }

      it "should find the associated project" do
        expect(user.signup_project).to eq(project)
      end
    end
  end

  describe '#display_name' do
    let(:user) { build(:user) }

    it 'should validate presence', :aggregate_failures do
      user.display_name = ""
      expect(user.valid?).to be_falsy
      expect(user.errors[:display_name]).to include("can't be blank")
    end

    it 'should allow duplicate display names' do
      user.save
      expect {
        create(:user, display_name: user.display_name)
      }.not_to raise_error
    end
  end

  describe '#login' do
    let(:user) { build(:user, migrated: true) }

    it 'should validate presence' do
      user.login = ""
      expect(user).to_not be_valid
    end

    it 'should not have whitespace' do
      user.login = " asdf asdf"
      expect(user).to_not be_valid
    end

    it 'should not have non alpha characters' do
      user.login = "asdf!fdsa"
      expect(user).to_not be_valid
    end

    it 'should allow dashes and underscores' do
      user.login = "abc-def_123"
      expect(user).to be_valid
    end

    it 'should not enfore a minimum length' do
      expect(build(:user, login: "1")).to be_valid
    end

    it 'should have non-blank error' do
      user = build(:user, login: "")
      user.valid?
      expect(user.errors[:login]).to include("can't be blank")
    end

    it 'should validate uniqueness to enable filtering by the display name' do
      login = 'Mista_Bob_Dobalina'
      aggregate_failures "testing different cases" do
        expect{ create(:user, login: login) }.not_to raise_error
        expect{
          create(:user, login: login.upcase, email: 'test2@example.com')
        }.to raise_error(ActiveRecord::RecordInvalid)
        expect{
          create(:user, login: login.downcase, email: 'test3@example.com')
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it "should have the correct case-insensitive uniqueness error" do
      user = create(:user)
      dup_user = build(:user, login: user.login.upcase)
      dup_user.valid?
      expect(dup_user.errors[:login]).to include("has already been taken")
    end

    it 'should constrain database uniqueness' do
      user = create :user
      dup_user = create :user

      expect {
        dup_user.update_attribute 'login', user.login.upcase
      }.to raise_error ActiveRecord::RecordNotUnique
    end
  end

  describe '#email' do

    context "when a user is setup" do
      let(:user) { create(:user, email: 'test@example.com') }

      it 'should raise an error trying to save a duplicate' do
        expect{ create(:user, email: user.email.upcase) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'should validate case insensitive uniqueness' do
        dup = build(:user, email: user.email.upcase)
        dup.valid?
        expect(dup.errors[:email]).to include("has already been taken")
      end

      it 'should constrain database uniqueness' do
        user = create :user
        dup_user = create :user

        expect {
          dup_user.update_attribute 'email', user.email
        }.to raise_error ActiveRecord::RecordNotUnique
      end
    end

    context "when a user is disabled and has no email" do
      subject { build(:user, email: nil, activated_state: :inactive) }

      it { is_expected.to be_valid }
    end
  end

  describe '#valid_email' do
    let(:user) { build(:user, email: 'isitvalid@example.com') }

    it 'should set the valid_email field to true' do
      expect(user.valid_email).to be_truthy
    end

    describe "setting the field to nil" do
      before(:each) do
        user.valid_email = nil
      end

      it 'should not be valid' do
        expect(user.valid?).to be_falsey
      end

      it 'should have the correct error message' do
        user.valid?
        expect(user.errors[:valid_email]).to include("must be true or false")
      end
    end
  end

  describe "#build_identity_group" do
    let(:user) { build(:user, build_group: false) }

    context "when a user has a valid login" do
      before(:each) do
        user.build_identity_group
        user.save!
        user.reload
      end

      it 'should a new membership with identity set to true' do
        expect(user.identity_membership.identity).to eq(true)
      end

      it 'should have a group with the same name as the user login' do
        expect(user.identity_group.name).to eq(user.login)
      end

      it 'should raise error if a user has an identity group' do
        user = create(:user)
        expect{ user.build_identity_group }.to raise_error(StandardError, "Identity Group Exists")
      end
    end

    context "when a user_group with the same name in different case exists" do
      let!(:user_group) { create(:user_group, name: user.login.upcase) }

      it "should not be valid" do
        expect do
          user.build_identity_group
          user.save!
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "should have the correct error message on the identity_group attribute" do
        user.build_identity_group
        user.valid?
        expect(user.errors[:"identity_group.display_name"]).to include("has already been taken")
      end
    end

    context "when the identity group is missing" do

      it "should not be valid" do
        expect(user.valid?).to be_falsy
      end

      it "should have the correct error message on the identity_group association" do
        user.valid?
        expect(user.errors[:identity_group]).to include("can't be blank")
      end
    end
  end

  describe "#password_required?" do
    it 'should require a password when creating with a new user' do
      aggregate_failures "different cases" do
        expect{ create(:user, password: "password1") }.not_to raise_error
        expect{ create(:user, password: nil) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it 'should not require a password when creating a user from an import' do
      attrs = {login: "Mr.T", hash_func: 'sha1', email: "test@example.com"}
      expect do
        User.create!(attrs) do |u|
          u.build_identity_group
        end
      end.to_not raise_error
    end
  end

  describe "#valid_password?" do
    it 'should validate user with bcrypted password' do
      expect(create(:user).valid_password?('password')).to be_truthy
    end

    it 'should validate length of user passwords' do
      user_errors = ->(attrs){ User.new(attrs).tap{ |u| u.valid? }.errors }
      expect(user_errors.call(password: 'ab12')).to have_key :password
      expect(user_errors.call(password: 'abcd1234')).to_not have_key :password
    end

    context "with the old sha1 hashing alg" do
      let(:user) do
        user = build(:insecure_user) do |u|
          u.hash_func = 'sha1'
          u.unsubscribe_token = nil
        end
        user.save(validate: false)
        user
      end

      it 'should validate imported user with sha1+salt password' do
        expect(user.valid_password?('tajikistan')).to be_truthy
      end

      it 'should not validate an imported user with an invalid password' do
        expect(user.valid_password?('nottheirpassword')).to be_falsey
      end

      it 'should update an imported user to use bcrypt hashing' do
        expect(user.hash_func).to eq("sha1")
        user.valid_password?('tajikistan')
        expect(user.hash_func).to eq("bcrypt")
      end

      it 'should add the unsubscribe token' do
        user.valid_password?('tajikistan')
        expect(user.unsubscribe_token).to_not be_nil
      end

      context "with an old short password" do
        let(:encrypted) { Sha1Encryption.encrypt('stan', user.password_salt) }

        it 'should allow old short passwords' do
          user.update_column(:encrypted_password, encrypted)
          expect { user.valid_password?("stan") }.not_to raise_error
        end
      end
    end
  end

  describe "#admin" do
    let(:user) { build(:user) }

    it "should be false by default" do
      expect(user.admin).to be false
    end
  end

  describe "#active_for_authentication?" do
    let(:user) { create(:user) }

    it "should call update_ouroboros_created on the model" do
      expect(user).to receive(:update_ouroboros_created)
      expect(user).not_to receive(:save)
      user.active_for_authentication?
    end

    it "should return true for an active user" do
      expect(user.active_for_authentication?).to eq(true)
    end

    it "should be false for a disabled user" do
      user.disable!
      expect(user.active_for_authentication?).to eq(false)
    end

    context "when the user was created by ouroboros" do
      let(:user) do
        User.skip_callback :validation, :before, :update_ouroboros_created
        u = build(:ouroboros_created_user)
        u.save(validate: false)
        User.set_callback :validation, :before, :update_ouroboros_created
        u
      end

      it "should update the model and be valid for auth" do
        aggregate_failures "active for auth" do
          expect(user).to receive(:update_ouroboros_created).twice.and_call_original
          expect(user).to receive(:build_identity_group).and_call_original
          expect(user).to receive(:setup_unsubscribe_token).and_call_original
          expect(user).to receive(:save).and_call_original
          expect(user.active_for_authentication?).to be true
          expect(user.reload.ouroboros_created).to be false
        end
      end
    end
  end

  describe "#languages" do
    context "when no languages are set" do

      it "should return an emtpy array for no set languages" do
        user = build(:user)
        expect(user.languages).to match_array([])
      end
    end
  end

  describe "#projects" do
    let(:user) { create(:project_owner) }

    it "should have many projects" do
      expect(user.projects).to all( be_a(Project) )
    end
  end

  describe "#memberships" do
    let(:user) { create(:user_group_member) }

    it "should have many user group members" do
      expect(user.memberships).to all( be_a(Membership) )
    end
  end

  describe "#user_groups" do
    let(:user) { create(:user_group_member) }

    it "should be a member of many user groups" do
      expect(user.user_groups).to all( be_a(UserGroup) )
    end
  end

  describe "#collections" do
    let(:user) { create(:user_with_collections) }

    it "should have many collections" do
      expect(user.collections).to all( be_a(Collection) )
    end
  end

  describe "#classifications" do
    let(:relation_instance) { user }

    it_behaves_like "it has a classifications assocation"
  end

  describe "::memberships_for" do
    let(:user) { create(:user_group_member) }
    let(:query_sql) { user.memberships_for(action, test_class).to_sql }
    let(:test_class) { Project }
    let(:action) { :update }

    context "supplied class" do
      it 'should query for editor roles for the supplied class' do
        expect(query_sql).to match(/project_editor/)
      end
    end

    context "no class" do
      let(:test_class) { nil }
      it 'should not add additional roles' do
        expect(query_sql).to_not match(/editor/)
      end
    end

    context "action is show" do
      let(:action) { :show }

      it 'should query for group_admin' do
        expect(query_sql).to match(/group_admin/)
      end

      it 'should query for group_member' do
        expect(query_sql).to match(/group_member/)
      end
    end

    context "action is index" do
      let(:action) { :index }

      it 'should query for group_admin' do
        expect(query_sql).to match(/group_admin/)
      end

      it 'should query for group_member' do
        expect(query_sql).to match(/group_member/)
      end
    end

    context "action is not show or index" do
      it 'should query for group_admin' do
        expect(query_sql).to match(/group_admin/)
      end

      it 'should not query for group member' do
        expect(query_sql).to_not match(/group_member/)
      end
    end
  end

  describe "#password" do
    it "should set a user's hash_func to bcrypt" do
      u = build(:insecure_user)
      u.password = 'newpassword'
      expect(u.hash_func).to eq('bcrypt')
    end
  end

  describe "#uploaded_subjects" do
    it 'should list the subjects a user has uploaded' do
      uploader = create(:user_with_uploaded_subjects)
      expect(uploader.uploaded_subjects).to all( be_a(Subject) )
    end
  end

  describe "#uploaded_subjects_count" do
    let(:uploader) { create(:user_with_uploaded_subjects) }

    it 'should have a count of the subjects a user has uploaded' do
      expect(uploader.uploaded_subjects_count).to eq(2)
    end

    it "should ensure the it casts invalid values" do
      ["", nil].each do |cast_val|
        cache_store = Rails.cache
        allow(cache_store).to receive(:fetch).and_return(cast_val)
        expect(uploader.uploaded_subjects_count).to eq(0)
      end
    end
  end

  describe "#increment_subjects_count_cache", :with_cache_store do
    it 'should return nil if no cache entry' do
      uploader = create(:user_with_uploaded_subjects)
      expect(uploader.increment_subjects_count_cache).to eq(nil)
    end

    it 'should inc the cache entry value if exists' do
      uploader = create(:user_with_uploaded_subjects)
      count = uploader.uploaded_subjects_count
      expect(uploader.increment_subjects_count_cache).to eq(count+1)
    end
  end

  describe "#update_ouroboros_created" do
    let(:user) do
      build(:ouroboros_created_user, login: "NOT ALLOWED")
    end

    it 'should set login from display_name' do
      user.update_ouroboros_created
      expect(user.login).to eq(described_class.sanitize_login(user.display_name))
    end

    it 'should build an identity group' do
      user.update_ouroboros_created
      user.save!
      user.reload
      expect(user.identity_group).to be_valid
    end

    it 'should run on validation' do
      expect(user).to be_valid
    end

    context "when the login is all unicode" do

      it "should use the zooniverse id for login field instead of leaving it blank" do
        non_ascii = "ẉơŕƌé"
        User.skip_callback :validation, :before, :update_ouroboros_created
        dup_user = build(:ouroboros_created_user, display_name: non_ascii, login: non_ascii)
        dup_user.save(validate: false)
        User.set_callback :validation, :before, :update_ouroboros_created
        aggregate_failures "dup user" do
          expect(dup_user).to be_valid
          expect(dup_user.login).to eq("panoptes-#{dup_user.id}")
        end
      end
    end

    context "when the ouroboros created user has a clashing sanitized login" do
      let(:dup_user) do
        build(:ouroboros_created_user, display_name: "#{user.login}é")
      end

      before(:each) { user.save }

      it "should append a suffix to the sanitized login" do
        dup_user.valid?
        aggregate_failures "dup user" do
          expect(dup_user).to be_valid
          expect(dup_user.login).to eq("#{user.login}-1")
        end
      end

      context "when it can't find a non-clashing sanitized login" do

        it "should time out after a set number of tries" do
          allow(User).to receive(:find_by_lower_login).and_return(user)
          dup_user.valid?
          expect(dup_user.login).to eq("#{user.login}-20")
        end
      end

      context "when validating a saved ouroboros created user" do

        it "should not append a suffix to the login" do
          prev_login = user.login
          user.update_column(:ouroboros_created, true)
          user.valid?
          expect(user.login).to eq(prev_login)
        end
      end
    end
  end

  describe '#non_identity_user_group_ids' do
    let(:user) { create :user }
    let(:user_group) { create :user_group }

    it 'returns an empty array when not a member of any groups apart from the identity group' do
      expect(user.identity_group).to be_present
      expect(user.non_identity_user_group_ids).to be_empty
    end

    it 'returns user group ids for memberships' do
      user.memberships.create! user_group: user_group, state: 'active'
      expect(user.non_identity_user_group_ids).to match_array([user_group.id])
    end

    it 'does not return ids from inactive memberships' do
      user.memberships.create! user_group: user_group, state: 'inactive'
      expect(user.non_identity_user_group_ids).to be_empty
    end
  end

  describe '#set_zooniverse_id' do
    let(:user){ create :user }
    subject{ user.zooniverse_id }
    it{ is_expected.to eql "panoptes-#{ user.id }" }
  end

  describe "#unsubscribe_token" do

    it "should not build one automatically on build" do
      expect(build(:user).unsubscribe_token).to be_nil
    end

    it "should build one automatically on create" do
      expect(user.unsubscribe_token).to_not be_nil
    end

    it "should not be valid with a duplicate" do
      allow_any_instance_of(User).to receive(:unsubscribe_token).and_return(user.unsubscribe_token)
      aggregate_failures "error messages" do
        user = build(:user)
        expect(user.valid?).to be_falsey
        expect(user.errors[:unsubscribe_token]).to include("has already been taken")
      end
    end
  end

  describe "#send_welcome_email after_create callback" do
    let(:user) { build(:user) }

    it "should send the welcome email" do
      expect(user).to receive(:send_welcome_email).once
      user.save!
    end

    it "should queue the worker with the user id" do
      allow(UserWelcomeMailerWorker).to receive :perform_async
      user.save!
      expect(UserWelcomeMailerWorker).to have_received(:perform_async).with(user.id, nil).ordered
    end

    context "when redis is unreachable" do
      it "should not raise an error on save" do
        [ Timeout::Error, Redis::TimeoutError, Redis::CannotConnectError ].each do |redis_error|
          allow(UserWelcomeMailerWorker).to receive(:perform_async).and_raise(redis_error)
          expect { user.save! }.not_to raise_error
        end
      end

      it "should send the welcome email in band" do
        allow(UserWelcomeMailerWorker).to receive(:perform_async).and_raise(Redis::CannotConnectError)
        expect_any_instance_of(UserWelcomeMailerWorker).to receive(:perform).with(Integer, nil)
        user.save!
      end
    end

    context "when the user has a project id" do
      let(:project) { create :project }
      let!(:user) { build(:user, project_id: project.id) }

      it "should queue the worker with the user id and project id" do
        allow(UserWelcomeMailerWorker).to receive :perform_async
        user.save!
        expect(UserWelcomeMailerWorker).to have_received(:perform_async).with(user.id, project.id).ordered
      end
    end

    context "when the user is created via a migration" do
      let!(:user) { build(:user, migrated: true) }

      it "should not queue the worker with the user id" do
        expect(UserWelcomeMailerWorker).not_to receive(:perform_async)
        user.save!
      end
    end
  end

  describe "#set_ouroboros_api_key" do
    it 'should set the key on creation' do
      user = create(:user, api_key: nil)
      expect(user.api_key).to_not be_nil
    end
  end

  describe '#subject_limit' do
    context 'the user model has a null limit' do
      it 'should return the Panotpes.max_subjects value' do
        user = create(:user)
        expect(user.subject_limit).to eq(Panoptes.max_subjects)
      end
    end

    context 'the user model has a defined limit' do
      it 'should return that limit' do
        user = create(:user, subject_limit: 10)
        expect(user.subject_limit).to eq(10)
      end
    end
  end

  describe '#uploaded_subjects_count' do

    context 'the user has no uploaded subject' do
      it 'should return 0' do
        user = create(:user)
        expect(user.uploaded_subjects_count).to eq(0)
      end
    end

    context 'the user has uploaded subject' do
      it 'should return 1' do
        user = create(:user)
        create(:subject, uploader: user)
        expect(user.uploaded_subjects_count).to eq(1)
      end
    end
  end

  describe "#sync_identity_group" do
    it 'should set the identity group login if the user login changes' do
      user.login = "test"
      user.save!
      user.reload
      expect(user.identity_group.name).to eq("test")
    end

    it 'should set the identity group display_name if the user display_name changes' do
      user.display_name = "test"
      user.save!
      user.reload
      expect(user.identity_group.display_name).to eq("test")
    end
  end

  describe "#favorite_collections_for_project" do
    let!(:fav_collection) { create(:collection, projects: [owned], owner: user, favorite: true) }

    it "returns the favorite collections for the project" do
      expect(user.favorite_collections_for_project(owned.id)).to eq([fav_collection])
    end
  end
end
