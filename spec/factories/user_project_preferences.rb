FactoryBot.define do
  factory :user_project_preference do
    transient do
      public false
    end

    user { create(:user, private_profile: !public) }
    project
    email_communication true
    preferences '{"tutorial": "done"}'
    activity_count 19

    factory :legacy_user_project_preference do
      activity_count nil
      legacy_count({"bars": 19, "candels": 10})

      factory :busted_legacy_user_project_preference do
        legacy_count('{"":null, "radio":"4"}')
      end
    end
  end
end
