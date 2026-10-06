# Settings > Account management: who it's switched on for, who's away, and what each person on the
# team is good at (for call debriefs). Each person then chooses their clients in My clients.
module AccountManagement
  class SettingsController < ApplicationController
    skip_before_action :require_member
    require_permission :manage_settings
    agent_tool :show_account_management_settings, on: :show, title: "Show who account management is switched on for"

    def show
      @members = Member.includes(:user, :chosen_clients).ordered.to_a
      @others = ::User.active.people.ordered.where.not(id: @members.map(&:user_id))
      @expertise = Expertise.tags_by_user
      @leading = Lead.group(:user_id).count
    end
  end
end
