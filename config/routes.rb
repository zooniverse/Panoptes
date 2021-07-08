ActionDispatch::Routing::Mapper.send :include, Routes::JsonApiRoutes

# require 'sidekiq/web' via
require 'sidekiq_unique_jobs/web'

Rails.application.routes.draw do

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
    flipper_block = lambda {
      Panoptes.flipper
    }
    mount Flipper::UI.app(flipper_block) => '/flipper'
  end

  post '/graphql', to: 'graphql#execute'
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'

  use_doorkeeper do
    controllers authorizations: 'authorizations',
                tokens: 'tokens',
                applications: 'applications'
  end

  devise_for :users,
    controllers: { passwords: 'passwords' },
    skip: [ :sessions, :registrations ]

  as :user do
    get "/users/sign_in" => "sessions#new", as: :new_user_session
    post "/users/sign_in" => "sessions#create", as: :user_session
    delete "/users/sign_out" => "sessions#destroy", as: :destroy_user_session

    get '/profile' => 'registrations#edit', as: :edit_user_registration
    get "/users/sign_up" => "registrations#new", as: :new_user_registration
    post "/users" => "registrations#create", as: :user_registration
    put "/users" => "registrations#update"
    delete "/users" => "registrations#destroy", as: :destroy_user_registration
  end

  get "unsubscribe", to: "emails#unsubscribe_via_token"
  post "unsubscribe", to: "emails#unsubscribe_via_email"

  namespace :api, constraints: { format: 'json' } do
    post "/events" => "events#create"
  end

  namespace :api do
    api_version(module: "V1", header: {name: "Accept", value: "application/vnd.api+json; version=1"}) do
      get "/me", to: 'users#me', format: false
      json_api_resources :aggregations

      json_api_resources :collection_roles

      json_api_resources :collection_preferences

      json_api_resources :set_member_subjects, links: [:retired_workflows]

      json_api_resources :project_roles

      json_api_resources :project_preferences do
        collection do
          post :update_settings
        end
      end

      json_api_resources :classifications do
        collection do
          get :gold_standard
          get :incomplete
          get :project
        end
      end

      json_api_resources :memberships

      json_api_resources :subjects do
        collection do
          get :queued # Subject selection end point
          get :grouped # SubjectGroup selection end point
          get :selection # Subject selection by subject ids end point
        end
      end

      json_api_resources :users, except: [:new, :edit, :create], links: [:user_groups] do
        get "/recents", to: "users#recents", format: false
        media_resources :avatar, :profile_header
      end

      json_api_resources :user_groups, links: [:users] do
        get "/recents", to: "user_groups#recents", format: false
      end

      json_api_resources :organizations, links: [:projects] do
        json_api_resources :pages, controller: "organization_pages"
        media_resources :avatar, :background, :attached_images
      end

      json_api_resources :organization_roles

      json_api_resources :projects, links: [:subject_sets, :workflows] do
        media_resources :avatar, :background, :attached_images,
          classifications_export: { except: [:create] },
          subjects_export: { except: [:create] },
          workflows_export: { except: [:create] },
          workflow_contents_export: { except: [:create] }

        post "/classifications_export", to: "projects#create_classifications_export", format: false
        post "/subjects_export", to: "projects#create_subjects_export", format: false
        post "/workflows_export", to: "projects#create_workflows_export", format: false
        post "/workflow_contents_export", to: "projects#create_workflow_contents_export", format: false
        post "/copy", to: "projects#copy", format: false

        json_api_resources :pages, controller: "project_pages"
      end

      json_api_resources :workflows, links: [:subject_sets, :retired_subjects, :tutorials, :workflow_versions, :published_version] do
        media_resources :attached_images, classifications_export: { except: [:create] }

        post "/retired_subjects", to: "workflows#retire_subjects"
        post '/unretire_subjects', to: 'workflows#unretire_subjects'
        post "/classifications_export", to: "workflows#create_classifications_export", format: false
        post '/publish', to: 'workflows#publish'
      end

      json_api_resources :workflow_versions, links: [:workflow]

      json_api_resources :subject_sets, links: [:subjects]

      json_api_resources :subject_set_imports, links: [:subject_sets, :users], only: [:index, :show, :create]

      json_api_resources :collections, links: [:subjects, :default_subject]

      json_api_resources :tags, only: [:index, :show]

      json_api_resources :tutorials do
        media_resources :attached_images
      end

      json_api_resources :field_guides do
        media_resources :attached_images
      end

      json_api_resources :subject_workflow_statuses, only: [:index, :show]

      json_api_resources(:translations, {
        links: [:published_version],
        constraints: Routes::Constraints::TranslationsConstraint.new,
        except: %i(new edit destroy)
      })

      json_api_resources :subject_groups, only: %w[index show]
    end
  end

  scope "subject_selection_strategies/:strategy", as: "subject_selection_strategy", constraints: { format: 'json' } do
    get "workflows", to: "subject_selection_strategies#workflows"
    get "subjects", to: "subject_selection_strategies#subjects"
  end

  get "health_check", to: "home#index"
  root to: "home#index"

  # In development mode, this route blocks access to the mailer preview pages that Rails has built-in.
  unless Rails.env.development?
    match "*path", to: "application#unknown_route", via: :all
  end
end
