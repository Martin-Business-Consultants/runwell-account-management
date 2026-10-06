# A client's meeting rhythm: starting one plans its first meeting; stopping it cancels the
# upcoming ones whose agenda hasn't gone out.
module AccountManagement
  class MeetingSeriesController < ApplicationController
    allow_staff
    before_action :set_client
    before_action :require_client_access
    agent_tool :start_meeting_rhythm, on: :create, title: "Set a client's meeting rhythm",
      description: "cadence: weekly, biweekly or monthly (the same weekday of the month as starts_on, e.g. the second Tuesday). starts_on: the first meeting's date; time_of_day: 24h, in the install's zone. The next meeting is always planned; each has its agenda due a day ahead.",
      params: { meeting_series: { title: "string!", cadence: MeetingSeries::CADENCES.keys, starts_on: "date!", time_of_day: "string", owner_id: "integer" } },
      next_tools: %i[list_meetings]
    agent_tool :stop_meeting_rhythm, on: :destroy, title: "Stop a client's meeting rhythm",
      description: "Cancels its upcoming meetings whose agenda hasn't gone out."

    def create
      attributes = params.expect(meeting_series: %i[title cadence starts_on time_of_day owner_id])
      owner = ::User.active.people.find_by(id: attributes.delete(:owner_id))
      series = @client.account_meeting_series.new(attributes.merge(owner: owner, created_by: Member.person(Current.user)))
      if series.save
        meeting = series.ensure_next!
        redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"),
          notice: "#{series.title}, #{series.label}. #{meeting ? "The first is #{meeting.when_label}." : ""}".strip
      else
        redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"), alert: series.errors.full_messages.to_sentence
      end
    end

    def destroy
      series = @client.account_meeting_series.find(params[:id])
      series.stop!
      redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"), notice: "Stopped #{series.title}."
    end
  end
end
