# A client call, debriefed: recorded with what came out of it (Call::Plan), and read back.
module AccountManagement
  class CallsController < ApplicationController
    allow_staff
    before_action :set_client, only: :create
    before_action :require_client_access, only: :create
    agent_tool :record_call, on: :create, title: "Record a client call and the work that came out of it",
      description: "From debrief_call's data. call: summary (a line), notes (the notes as given), happened_on, channel, contact_ids, meeting_id. todos: each on an open engagement of this client (its ref), with title and owner_id (by expertise), and due_on, scope_item_id, description, client_visible when known. commitments: owner_kind us (user_id) or client (contact_id), with due_on. requests: asks outside the agreed scope. health: this week's, if the call changed it. With preview: true it writes nothing and returns the plan by name with any errors: show it to the person, then call again without preview. Without it, everything is made at once, or nothing.",
      params: {
        call: { summary: "string!", notes: "text", happened_on: "date", channel: Call::CHANNELS.keys, meeting_id: "integer", contact_ids: "integer[]" },
        todos: [ { engagement: "string!", title: "string!", owner_id: "integer!", description: "text", due_on: "date", scope_item_id: "integer", client_visible: "boolean" } ],
        commitments: [ { description: "string!", owner_kind: ::Commitment::OWNER_KINDS, user_id: "integer", contact_id: "integer", due_on: "date!", engagement: "string" } ],
        requests: [ { subject: "string!", body: "text" } ],
        health: { status: HealthCheck::STATUSES.keys, reason: "string" },
        preview: "boolean"
      }
    agent_tool :show_call, on: :show, title: "Show a debriefed call and what came out of it"
    agent_tool :list_calls, on: :index, title: "List debriefed calls", params: { client_id: "integer" }

    def index
      scope = Call.where(client_id: current_member.client_ids).includes(:client, :user).recent
      scope = scope.where(client_id: params[:client_id]) if params[:client_id].present?
      @calls = paginate scope
    end

    def create
      plan = Call::Plan.new(client: @client, user: Current.user, params: params.to_unsafe_h.slice("call", "todos", "commitments", "requests", "health"))

      if ActiveModel::Type::Boolean.new.cast(params[:preview])
        render json: { status: plan.valid? ? "ok" : "error", code: ("invalid" unless plan.valid?),
          summary: plan.valid? ? "Would record the call with #{@client.name}: #{plan.summary_line}." : "The plan has problems: #{plan.errors.to_sentence}",
          preview: plan.preview }.compact, status: plan.valid? ? :ok : :unprocessable_entity
      elsif plan.valid?
        call = plan.apply!
        redirect_to account_management_call_path(call), notice: "Recorded the call with #{@client.name}: #{plan.summary_line}.#{" Note: #{plan.warnings.to_sentence}." if plan.warnings.any?}"
      else
        render json: { status: "error", code: "invalid", summary: "Nothing was recorded: #{plan.errors.to_sentence}", errors: plan.errors }, status: :unprocessable_entity
      end
    end

    def show
      @call = Call.find(params[:id])
      @client = @call.client
    end
  end
end
