# Today: everything that needs you across the clients you work with, most urgent first.
module AccountManagement
  class TodaysController < ApplicationController
    allow_staff
    agent_tool :show_account_today, on: :show, title: "What needs you today across your clients",
      description: "Start here. Overdue, today, this week and keep-an-eye-on items across the clients you work with: agendas and recaps, requests to answer, our commitments, quiet clients, what we're waiting on clients for (with a nudge), health to set, digests to send, your weekly update, accounts and checklists. Snoozed items are left out until their time."

    def show
      @cockpit = Cockpit.new(Current.user, member: current_member)
    end
  end
end
