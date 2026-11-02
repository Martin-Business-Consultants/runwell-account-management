# Account management 0.4, for Runwell 3.0, where commitments and requests became work. What we
# promise is now a todo; what a client promises (which the core no longer keeps) is a promise here.
# A meeting's action items and a call's results point at those instead of commitments and requests.
#
# The core's MergeCommitmentsAndRequestsIntoTodos copied commitments and requests into todos
# without keeping a map, so each old link is matched to its todo by client, title and creation
# time; the core's commitments table still holds the client's promises, which are copied across.
class WorkAndPromises < ActiveRecord::Migration[8.1]
  class Promise < ActiveRecord::Base
    self.table_name = "account_management_promises"
  end

  class MeetingItem < ActiveRecord::Base
    self.table_name = "account_management_meeting_items"
  end

  class CallItem < ActiveRecord::Base
    self.table_name = "account_management_call_items"
  end

  class Todo < ActiveRecord::Base
    self.table_name = "todos"
  end

  class Commitment < ActiveRecord::Base
    self.table_name = "commitments"
  end

  class Request < ActiveRecord::Base
    self.table_name = "requests"
  end

  def up
    create_table :account_management_promises do |t|
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.references :engagement, foreign_key: { on_delete: :nullify }
      t.references :contact, foreign_key: { on_delete: :nullify }
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :description, null: false
      t.date :due_on, null: false
      t.string :resolution
      t.datetime :resolved_at
      t.string :source
      t.integer :legacy_commitment_id, index: true
      t.timestamps
    end

    change_table :account_management_meeting_items do |t|
      t.references :todo, foreign_key: { on_delete: :cascade }
      t.references :promise, foreign_key: { to_table: :account_management_promises, on_delete: :cascade }
    end
    change_column_null :account_management_meeting_items, :commitment_id, true

    add_column :account_management_call_items, :kind, :string

    copy_client_promises
    relink_meeting_items
    relink_call_items
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private
    def copy_client_promises
      return unless table_exists?(:commitments)

      Commitment.where(owner_kind: "client").find_each do |commitment|
        Promise.create!(client_id: commitment.client_id, engagement_id: commitment.engagement_id, contact_id: commitment.contact_id,
          description: commitment.description, due_on: commitment.due_on, resolution: commitment.resolution,
          resolved_at: commitment.resolved_at, source: commitment.source, legacy_commitment_id: commitment.id,
          created_at: commitment.created_at, updated_at: commitment.updated_at)
      end
    end

    def relink_meeting_items
      MeetingItem.where.not(commitment_id: nil).find_each do |item|
        case (found = from_commitment(item.commitment_id))
        when Promise then item.update_columns(promise_id: found.id)
        when Todo then item.update_columns(todo_id: found.id)
        else item.delete
        end
      end
    end

    def relink_call_items
      CallItem.where(item_type: "Todo").update_all(kind: "work")
      CallItem.where(item_type: %w[Commitment Request]).find_each do |item|
        found = item.item_type == "Commitment" ? from_commitment(item.item_id) : from_request(item.item_id)
        case found
        when Promise then item.update_columns(item_type: "AccountManagement::Promise", item_id: found.id, kind: "promise")
        when Todo then item.update_columns(item_type: "Todo", item_id: found.id, kind: item.item_type == "Request" ? "request" : "work")
        else item.delete
        end
      end
    end

    def from_commitment(id)
      return unless table_exists?(:commitments) && (commitment = Commitment.find_by(id: id))
      return Promise.find_by(legacy_commitment_id: commitment.id) if commitment.owner_kind == "client"

      Todo.find_by(client_id: commitment.client_id, title: commitment.description, created_at: commitment.created_at)
    end

    def from_request(id)
      return unless table_exists?(:requests) && (request = Request.find_by(id: id))
      return Todo.find_by(id: request.promoted_id) if request.promoted_type == "Todo"

      Todo.find_by(client_id: request.client_id, title: request.subject, created_at: request.received_at || request.created_at)
    end
end
