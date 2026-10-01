# Account management 0.2: the people it's switched on for and the clients each works with; every
# client contact logged; meetings on a rhythm; each client's health week by week; who's who at
# the client; onboarding and offboarding checklists; snoozed items on Today; and the weekly digest
# a client can get. A lead gets a backup, a contact cadence and the digest switch.
class KeepClientsInPlay < ActiveRecord::Migration[8.1]
  def up
    create_table :account_management_members do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :client_scope, null: false, default: "all"
      t.date :away_until
      t.references :activated_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :account_management_member_clients do |t|
      t.references :member, null: false, foreign_key: { to_table: :account_management_members, on_delete: :cascade }
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :account_management_member_clients, [ :member_id, :client_id ], unique: true

    change_table :account_management_leads do |t|
      t.references :backup_user, foreign_key: { to_table: :users }
      t.integer :contact_every_days
      t.boolean :digest_enabled, null: false, default: false
    end

    create_table :account_management_touches do |t|
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.references :engagement, foreign_key: { on_delete: :nullify }
      t.references :contact, foreign_key: { on_delete: :nullify }
      t.references :user, foreign_key: true
      t.references :subject, polymorphic: true
      t.string :channel, null: false
      t.string :direction, null: false, default: "out"
      t.string :source, null: false, default: "logged"
      t.text :summary
      t.datetime :happened_at, null: false
      t.timestamps
    end
    add_index :account_management_touches, [ :client_id, :happened_at ]

    create_table :account_management_meeting_series do |t|
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.references :engagement, foreign_key: { on_delete: :nullify }
      t.references :owner, foreign_key: { to_table: :users }
      t.references :created_by, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.string :cadence, null: false
      t.date :starts_on, null: false
      t.string :time_of_day, null: false, default: "10:00"
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_reference :account_management_meetings, :series, foreign_key: { to_table: :account_management_meeting_series, on_delete: :nullify }

    create_table :account_management_health_checks do |t|
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, foreign_key: true
      t.date :week_of, null: false
      t.string :status, null: false
      t.string :reason
      t.timestamps
    end
    add_index :account_management_health_checks, [ :client_id, :week_of ], unique: true

    create_table :account_management_contact_profiles do |t|
      t.references :contact, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.json :roles, null: false, default: []
      t.string :preferred_channel
      t.timestamps
    end

    create_table :account_management_checklists do |t|
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.references :started_by, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.json :done, null: false, default: {}
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.timestamps
    end
    add_index :account_management_checklists, [ :client_id, :kind ], unique: true

    create_table :account_management_snoozes do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :item_key, null: false
      t.datetime :until, null: false
      t.timestamps
    end
    add_index :account_management_snoozes, [ :user_id, :item_key ], unique: true

    create_table :account_management_digests do |t|
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.references :sent_by, foreign_key: { to_table: :users }
      t.date :week_of, null: false
      t.text :body
      t.datetime :sent_at
      t.string :sent_to
      t.timestamps
    end
    add_index :account_management_digests, [ :client_id, :week_of ], unique: true

    # Whoever already leads a client keeps working as before: switched on, with every client.
    execute <<~SQL
      INSERT INTO account_management_members (user_id, client_scope, created_at, updated_at)
      SELECT DISTINCT user_id, 'all', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM account_management_leads
    SQL
  end

  def down
    remove_reference :account_management_meetings, :series
    %i[digests snoozes checklists contact_profiles health_checks meeting_series touches member_clients members].each do |table|
      drop_table :"account_management_#{table}"
    end
    change_table :account_management_leads do |t|
      t.remove_references :backup_user
      t.remove :contact_every_days, :digest_enabled
    end
  end
end
