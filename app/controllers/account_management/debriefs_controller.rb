# Debriefing a client call: everything an AI harness needs to turn its notes into work, as data
# and as Markdown to paste.
module AccountManagement
  class DebriefsController < ApplicationController
    allow_staff
    before_action :set_client
    agent_tool :debrief_call, on: :show, title: "Get what's needed to debrief a client call",
      description: "Start here when someone shares notes from a call with a client. Returns the client's people, its open engagements with their agreed scope (scope_item_id) and open work, meetings around now, what we're waiting on them for, the team with each person's expertise tags, open work and whether they're away, the steps to follow, and an example for record_call.",
      next_tools: %i[record_call]

    def show
      @debrief = Debrief.new(@client)
    end
  end
end
