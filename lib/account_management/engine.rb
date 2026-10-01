module AccountManagement
  # A Runwell plugin: the working system of whoever runs client relationships, switched on per
  # person (Member) in Settings > Account management; each chooses all clients or a group. Each
  # client has a lead and a backup, a contact cadence and, optionally, a weekly digest. Today
  # (Cockpit) lists what needs someone across their clients, most urgent first. Every contact is
  # logged (Touch) and, with meetings, notes, requests and approvals, says when a client last
  # heard from us (Pulse); requests are answered within a business day (Replies); what we're
  # waiting on a client for can be nudged (Waiting). Meetings run on a rhythm (MeetingSeries),
  # with agendas and recaps drafted from the records. Each client's health is set weekly, who's
  # who at the client is recorded (ContactProfile), and onboarding and offboarding are checklists.
  # The access register, weekly updates and a scorecard against the playbook complete it. Owns
  # its tables and reaches the core only through Runwell::Plugins and load hooks. docs/guide.md
  # is the user's guide.
  class Engine < ::Rails::Engine
    initializer "account_management.routes" do |app|
      app.routes.append do
        scope "accounts", module: "account_management", as: "account_management" do
          get "/", to: "todays#show", as: :root
          get "team", to: "dashboards#show", as: :team
          resource :guide, only: :show
          resource :playbook, only: :show
          resource :settings, only: :show
          resources :members, only: %i[create update destroy]
          resource :portfolio, only: %i[show update]
          resources :people, only: %i[index update]
          resources :calls, only: %i[index show]
          resources :scorecards, only: :show
          resources :meetings do
            member do
              post :send_agenda
              post :send_recap
              post :cancel
              post :draft_agenda
              post :draft_recap
            end
            resources :action_items, only: :create
          end
          resources :accesses, except: :show do
            post :verify, on: :member
          end
          resources :clients, only: :index do
            resource :lead, only: :update
            resources :health_checks, only: :create
            resources :meeting_series, only: %i[create destroy]
            resources :checklists, only: %i[create destroy] do
              post :toggle, on: :member
            end
            resource :digest, only: %i[show update] do
              post :deliver
            end
            resource :debrief, only: :show
            resources :calls, only: :create
          end
          resources :contacts, only: [] do
            resource :profile, only: :update, controller: "contact_profiles"
          end
          resources :touches, only: %i[index create destroy]
          resources :nudges, only: %i[new create]
          resource :snooze, only: %i[create destroy]
          resources :weekly_updates, path: "updates", except: :destroy do
            post :submit, on: :member
          end
        end
      end
    end

    initializer "account_management.helpers" do
      ActiveSupport.on_load(:action_view) { include AccountManagement::AccountsHelper }
    end

    initializer "account_management.models" do
      ActiveSupport.on_load(:runwell_client) do
        has_one :account_lead, class_name: "AccountManagement::Lead", dependent: :destroy
        has_many :account_touches, class_name: "AccountManagement::Touch", dependent: :delete_all
        has_many :account_health_checks, class_name: "AccountManagement::HealthCheck", dependent: :delete_all
        has_many :account_meeting_series, class_name: "AccountManagement::MeetingSeries", dependent: :destroy
        has_many :account_checklists, class_name: "AccountManagement::Checklist", dependent: :delete_all
        has_many :account_calls, class_name: "AccountManagement::Call", dependent: :destroy
        has_many :account_meetings, class_name: "AccountManagement::Meeting", dependent: :destroy
        has_many :account_accesses, class_name: "AccountManagement::Access", dependent: :destroy
      end
      ActiveSupport.on_load(:runwell_engagement) do
        has_many :account_meetings, class_name: "AccountManagement::Meeting", dependent: :nullify
      end
      ActiveSupport.on_load(:runwell_user) do
        has_many :account_leads, class_name: "AccountManagement::Lead", dependent: :destroy
        has_many :account_meetings, class_name: "AccountManagement::Meeting", foreign_key: :owner_id, dependent: :nullify
        has_many :weekly_updates, class_name: "AccountManagement::WeeklyUpdate", dependent: :destroy
        has_one :account_member, class_name: "AccountManagement::Member", dependent: :destroy
        has_one :account_expertise, class_name: "AccountManagement::Expertise", dependent: :destroy
      end
    end

    config.to_prepare do
      Runwell::Plugins.register :account_management, name: "Account management", version: AccountManagement::VERSION, author: "Runwell",
        enabled_by_default: false, requires: ">= 2.1.3", homepage: "https://github.com/Martin-Business-Consultants/runwell-account-management",
        description: "Keeps every client in play for the project managers it’s switched on for: a Today list across their clients, contacts logged and quiet clients flagged, requests answered within a business day, meeting rhythms with drafted agendas and recaps, nudges for what clients owe us, weekly health, who’s who at each client, onboarding and offboarding checklists, backup leads, and an optional weekly digest for clients."
      Runwell::Plugins.nav :account_management, "Accounts", -> { account_management_root_path if AccountManagement::Member.active?(Current.user) }
      Runwell::Plugins.settings :account_management, "Account management", -> { account_management_settings_path }
      Runwell::Plugins.permission :account_management, :manage_accounts, name: "Assign account leads and keep the access register", roles: %w[owner manager]
      Runwell::Plugins.permission :account_management, :view_scorecards, name: "See everyone’s account scorecard and weekly updates", roles: %w[owner manager]
      Runwell::Plugins.slot :client_panel, :account_management, "account_management/slots/client_panel"
      Runwell::Plugins.slot :engagement_panel, :account_management, "account_management/slots/engagement_panel"
      Runwell::Plugins.quick_action :account_management, label: "Contact", title: "Log a client contact", icon: "comment",
        partial: "account_management/quick_actions/contact", types: AccountManagement::Meeting::RECORD_TYPES,
        context: ->(record) { AccountManagement::Meeting::RECORD_TYPES.include?(record.class.name) ? record : record.try(:engagement) || record.try(:client) }
      Runwell::Plugins.briefing :account_management, "Accounts need you", partial: "account_management/briefing/item",
        items: ->(user) { AccountManagement::Attention.items(user) }
      Runwell::Plugins.agent_workflow :account_management, "Debrief a client call", <<~TEXT if Runwell::Plugins.respond_to?(:agent_workflow)
        When someone shares notes from a call with a client (pasted, or a file), turn them into work:
        1. Find the client (`search`), then `debrief_call --client_id <id>`: its people, open engagements with agreed scope, open work, and the team with expertise and workload.
        2. Plan todos (each on the engagement whose scope covers it, owner by expertise, less open work breaks ties, never someone away), commitments (theirs and ours, dated), requests (asks outside the agreed scope) and health.
        3. `record_call` with `preview: true`; show the person the plan as a table (engagement, todo, owner, due) and change what they say.
        4. `record_call` without preview. It records the notes, logs the contact and makes everything at once.
      TEXT
      Runwell::Plugins.nightly :account_management, -> { AccountManagement::MeetingSeries.active.find_each(&:ensure_next!) }
      Runwell::Plugins.stylesheet :account_management, "account_management/accounts"
    end
  end
end
