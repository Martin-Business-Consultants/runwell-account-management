# Turning a client call into work: each person's expertise, so an AI (or a person) can give each
# todo to the right owner, and each call recorded with what came out of it.
class DebriefCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :account_management_expertises do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.json :tags, null: false, default: []
      t.string :note
      t.timestamps
    end

    create_table :account_management_calls do |t|
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.references :meeting, foreign_key: { to_table: :account_management_meetings, on_delete: :nullify }
      t.references :note, foreign_key: { on_delete: :nullify }
      t.references :user, foreign_key: true
      t.string :channel, null: false, default: "call"
      t.string :summary, null: false
      t.datetime :happened_at, null: false
      t.timestamps
    end
    add_index :account_management_calls, [ :client_id, :happened_at ]

    create_table :account_management_call_items do |t|
      t.references :call, null: false, foreign_key: { to_table: :account_management_calls, on_delete: :cascade }
      t.references :item, polymorphic: true, null: false
      t.timestamps
    end
  end
end
