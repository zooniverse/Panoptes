FactoryBot.define do
  factory :user do
    transient do
      build_group { true }
    end

    hash_func { 'bcrypt' }
    sequence(:email) {|n| "example#{n}@example.com"}
    password { 'password' }
    encrypted_password { User.new.send(:password_digest, 'password') }
    credited_name { 'Dr User' }
    activated_state { :active }
    sequence(:login) { |n| "new_user_#{n}" }
    display_name{ login.try(:titleize) || login }
    global_email_communication { true }
    project_email_communication { true }
    beta_email_communication { true }
    nasa_email_communication { false }
    admin { false }
    banned { false }

    after(:build) do |u, env|
      if env.build_group
        u.identity_group = build(:user_group, name: u.login)
        u.identity_membership = build(:membership, user: u, user_group: u.identity_group, state: 0, identity: true, roles: ["group_admin"])
        # ensure we link the identity group to the idenity membership build strategy
        u.identity_group.identity_membership = u.identity_membership
      end
    end

    trait :avatar do
      after(:build) do |u|
        u.avatar = build(:medium, type: "user_avatar", linked: u)
      end
    end

    trait :languages do
      languages { ['en', 'es', 'fr-ca'] }
    end

    factory :insecure_user do
      # hash_func 'sha1' # hash func is not set via build / create
      # password 'tajikistan' # password will set the hash_func to bcrypt
      encrypted_password { 'zKUhbXyjCsgmcv6Fh5rQiHTzJWI=' }
      password_salt { 'nK5bXjD2YS7LSYndVJNGGdY=' }
    end

    factory :project_owner do
      after(:create) do |user|
        user.projects.concat(create_list(:project, 2))
        user.save!
      end
    end

    factory :user_group_member do
      after(:create) do |user|
        create_list(:membership, 1, user: user)
      end
    end

    factory :user_with_collections do
      after(:create) do |user|
        user.collections.concat(create_list(:collection, 2))
        user.save!
      end
    end

    factory :inactive_user do
      activated_state { :inactive }
      login { 'deleted_user' }
      email { 'deleted_user@zooniverse.org' }
    end

    factory :admin_user do
      admin { true }
    end

    factory :user_with_uploaded_subjects do
      after(:create) do |u|
        u.uploaded_subjects = create_list(:subject, 2, uploader: u)
        u.save!
      end
    end

    factory :ouroboros_created_user do
      build_group { false }
      ouroboros_created { true }
    end
  end
end
