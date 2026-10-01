# Your clients at a glance, riskiest first: health, last contact, lead, next meeting and what
# we're waiting on them for.
module AccountManagement
  class ClientsController < ApplicationController
    allow_staff
    agent_tool :list_account_clients, on: :index, title: "List your clients with their health and last contact",
      description: "Each client you work with: its health this week, when it last heard from us and whether it's quiet, its lead and backup, its next meeting, and what we're waiting on it for. Riskiest first."

    def index
      clients = current_member.clients.includes(account_lead: %i[user backup_user]).to_a
      ids = clients.map(&:id)
      @pulse = Pulse.new(ids)
      @health = HealthCheck.latest_for(ids)
      @next_meetings = Meeting.upcoming.where(client_id: ids).group_by(&:client_id).transform_values(&:first)
      @waiting = Waiting.items(ids).group_by { it.client.id }
      @clients = clients.sort_by { [ HealthCheck::RISK.fetch(@health[it.id]&.status, 1), @pulse.quiet?(it) ? 0 : 1, it.name ] }
    end
  end
end
