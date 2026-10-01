# Switching account management on or off for a person (an owner, from Settings).
module AccountManagement
  class MembersController < ApplicationController
    skip_before_action :require_member
    require_permission :manage_settings
    agent_tool :switch_on_account_management, on: :create, title: "Switch account management on for a person",
      description: "user_id: a person (Settings > People). They start with every client; they can narrow it in My clients.",
      params: { user_id: "integer!" }
    agent_tool :set_account_member_away, on: :update, title: "Set someone away (or back)",
      description: "away_until: the last day they're away; blank when they're back. While away, each client they lead goes to its backup.",
      params: { member: { away_until: "date" } }
    agent_tool :switch_off_account_management, on: :destroy, title: "Switch account management off for a person",
      description: "The member id from show_account_management_settings. What they led stays led; their clients' warnings go to the backup or to whoever may manage accounts."

    def create
      user = ::User.active.people.find(params[:user_id])
      Member.find_or_create_by!(user: user) { it.activated_by = Current.user }
      redirect_to account_management_settings_path, notice: "Account management is on for #{user.display_name}. They’ll find it under Accounts."
    end

    def update
      member = Member.find(params[:id])
      member.update!(away_until: params.dig(:member, :away_until).presence)
      redirect_to account_management_settings_path, notice: member.away? ? "#{member.user.display_name} is away until #{member.away_until.to_fs(:long)}." : "#{member.user.display_name} is back."
    end

    def destroy
      member = Member.find(params[:id])
      member.destroy!
      redirect_to account_management_settings_path, notice: "Account management is off for #{member.user.display_name}."
    end
  end
end
