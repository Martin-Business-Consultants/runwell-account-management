# Setting a client's health for this week.
module AccountManagement
  class HealthChecksController < ApplicationController
    allow_staff
    before_action :set_client
    before_action :require_client_access
    agent_tool :set_client_health, on: :create, title: "Set a client's health this week",
      description: "status: on_track, at_risk or off_track; reason: one line, required unless on track. One per client per week (setting it again replaces this week's). It goes into Friday's weekly update.",
      params: { status: HealthCheck::STATUSES.keys, reason: "string" }

    def create
      check = HealthCheck.record!(client: @client, status: params[:status], reason: params[:reason], user: Member.person(Current.user))
      redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"), notice: "#{@client.name}: #{check.label.downcase} this week."
    rescue ActiveRecord::RecordInvalid => error
      redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"), alert: error.record.errors.full_messages.to_sentence
    end
  end
end
