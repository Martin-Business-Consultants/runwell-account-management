# Settings > Account management: who it's switched on for. Each person then chooses their clients
# in My clients.
module AccountManagement
  class SettingsController < ApplicationController
    skip_before_action :require_member
    require_permission :manage_settings
    agent_tool :show_account_management_settings, on: :show, title: "Show who account management is switched on for"

    def show
      @members = Member.includes(:user, :chosen_clients).ordered.to_a
      @others = ::User.active.people.ordered.where.not(id: @members.map(&:user_id))
    end
  end
end
