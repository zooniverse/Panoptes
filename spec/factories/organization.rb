FactoryGirl.define do
  factory :organization do
    transient do
      build_contents true
      build_media false
    end

    sequence(:name) { |n| "test_org_#{ n }" }
    sequence(:display_name) { |n| "Test Organization #{ n }" }
    listed_at Time.now
    primary_language "en"

    association :owner, factory: :user

    after(:build) do |o, env|
      if env.build_contents
        o.organization_contents << build_list(:organization_content, 1, organization: o, language: o.primary_language)
        o.organization_contents << build_list(:organization_content, 1, organization: o, language: 'en-US')
      end

      if env.build_media
        o.avatar = create(:medium, type: "organization_avatar", linked: o)
        o.background = create(:medium, type: "organization_background", linked: o)
      end
    end
  end
end