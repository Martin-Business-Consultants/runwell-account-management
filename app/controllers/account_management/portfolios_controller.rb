# My clients: the clients you work with (every one, or those you choose; the ones you lead or
# back up are always yours), and when you're away.
module AccountManagement
  class PortfoliosController < ApplicationController
    allow_staff
    agent_tool :show_my_clients, on: :show, title: "Show the clients you work with"
    agent_tool :choose_my_clients, on: :update, title: "Choose the clients you work with",
      description: "client_scope: all (every client) or selected (client_ids). The clients you lead or back up are always included. away_until: the last day you're away, blank when back; while away your clients go to their backups.",
      params: { member: { client_scope: Member::SCOPES.keys, client_ids: "integer[]", away_until: "date" } }

    def show
      @clients = ::Client.active.ordered
      @fixed = Lead.where(user: Current.user).or(Lead.where(backup_user: Current.user)).pluck(:client_id).to_set
    end

    def update
      attributes = params.expect(member: [ :client_scope, :away_until, client_ids: [] ])
      current_member.choose!(scope: attributes[:client_scope].presence_in(Member::SCOPES.keys) || current_member.client_scope,
        client_ids: Array(attributes[:client_ids]).compact_blank)
      current_member.update!(away_until: attributes[:away_until].presence) if attributes.key?(:away_until)
      redirect_to account_management_portfolio_path,
        notice: current_member.all_clients? ? "You work with every client." : "You work with #{helpers.pluralize(current_member.clients.count, "client")}."
    end
  end
end
