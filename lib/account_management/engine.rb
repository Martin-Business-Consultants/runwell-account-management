module AccountManagement
  # A Runwell plugin: the working system of whoever runs client relationships, switched on per
  # person (Member) in Settings > Account management; each chooses all clients or a group. It does
  # five things. Today (Cockpit) lists what needs someone across their clients, most urgent first.
  # Clients shows each one's lead and backup (Lead), its health this week (HealthCheck) and when it
  # last heard from us (Pulse). Every contact is logged (Touch), and requests are answered within a
  # business day (Replies). Meetings carry an agenda before and a recap after, on a rhythm
  # (MeetingSeries). After a call, an AI harness debriefs it into work (Debrief, Call::Plan). Owns
  # its tables and reaches the core only through Runwell::Plugins and load hooks. docs/guide.md is
  # the user's guide.
  #
  # Tables left from features it no longer has (accesses, checklists, contact profiles, digests,
  # weekly updates) are kept until a later release drops them. The access register's rows point
  # at their client without a cascade, so clear_retired_rows removes them before a client goes.
  class Engine < ::Rails::Engine
    initializer "account_management.routes" do |app|
      app.routes.append do
        scope "accounts", module: "account_management", as: "account_management" do
          get "/", to: "todays#show", as: :root
          resource :guide, only: :show
          resource :settings, only: :show
          resources :members, only: %i[create update destroy]
          resource :portfolio, only: %i[show update]
          resources :people, only: :update
          resources :calls, only: %i[index show]
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
          resources :clients, only: :index do
            resource :lead, only: :update
            resources :health_checks, only: :create
            resources :meeting_series, only: %i[create destroy]
            resource :debrief, only: :show
            resources :calls, only: :create
          end
          resources :touches, only: %i[index create destroy]
          resource :snooze, only: %i[create destroy]
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
        has_many :account_calls, class_name: "AccountManagement::Call", dependent: :destroy
        has_many :account_meetings, class_name: "AccountManagement::Meeting", dependent: :destroy
        before_destroy { AccountManagement::Engine.clear_retired_rows(self) }
      end
      ActiveSupport.on_load(:runwell_engagement) do
        has_many :account_meetings, class_name: "AccountManagement::Meeting", dependent: :nullify
      end
      ActiveSupport.on_load(:runwell_user) do
        has_many :account_leads, class_name: "AccountManagement::Lead", dependent: :destroy
        has_many :account_meetings, class_name: "AccountManagement::Meeting", foreign_key: :owner_id, dependent: :nullify
        has_one :account_member, class_name: "AccountManagement::Member", dependent: :destroy
        has_one :account_expertise, class_name: "AccountManagement::Expertise", dependent: :destroy
      end
    end

    def self.clear_retired_rows(client)
      connection = ActiveRecord::Base.connection
      return unless connection.table_exists?(:account_management_accesses)

      connection.exec_delete("DELETE FROM account_management_accesses WHERE client_id = #{Integer(client.id)}")
    end

    config.to_prepare do
      Runwell::Plugins.register :account_management, name: "Account management", version: AccountManagement::VERSION, author: "Runwell",
        enabled_by_default: false, requires: ">= 2.21.0", homepage: "https://github.com/Martin-Business-Consultants/runwell-account-management",
        description: "Keeps every client in play for the people who look after them: a Today list of what needs you, each client’s lead, health and last contact, every contact logged, meetings with agendas and recaps, and call notes debriefed into work by AI."
      Runwell::Plugins.nav :account_management, "Accounts", -> { account_management_root_path if AccountManagement::Member.active?(Current.user) }
      Runwell::Plugins.settings :account_management, "Account management", -> { account_management_settings_path }
      Runwell::Plugins.permission :account_management, :manage_accounts, name: "Assign account leads and set the team’s expertise", roles: %w[owner manager]
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
