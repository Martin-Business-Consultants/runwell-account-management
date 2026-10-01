# A client's onboarding or offboarding checklist: start it, tick its steps, or remove it.
module AccountManagement
  class ChecklistsController < ApplicationController
    allow_staff
    before_action :set_client
    before_action :require_client_access
    agent_tool :start_checklist, on: :create, title: "Start a client's onboarding or offboarding checklist",
      params: { kind: Checklist::KINDS.keys }
    agent_tool :tick_checklist_step, on: :toggle, title: "Tick (or untick) a checklist step",
      description: "step: its key, from list_account_clients or the client's page. Steps that tick themselves from the records can't be ticked by hand.",
      params: { step: "string!" }
    agent_tool :remove_checklist, on: :destroy, title: "Remove a checklist started by mistake"

    def create
      checklist = @client.account_checklists.find_or_create_by!(kind: params[:kind].presence_in(Checklist::KINDS.keys) || "onboarding") do |it|
        it.started_at = Time.current
        it.started_by = Member.person(Current.user)
      end
      checklist.settle!
      redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"), notice: "#{checklist.label} started: #{checklist.done_count} of #{checklist.steps.size} steps already done."
    end

    def toggle
      checklist = @client.account_checklists.find(params[:id])
      checklist.toggle!(params[:step], user: Member.person(Current.user))
      redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"),
        notice: checklist.complete? ? "#{checklist.label} done." : "#{checklist.done_count} of #{checklist.steps.size} steps done."
    rescue ArgumentError => error
      redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"), alert: error.message
    end

    def destroy
      @client.account_checklists.find(params[:id]).destroy!
      redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"), notice: "Removed the checklist."
    end
  end
end
