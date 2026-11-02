# An action item from a meeting, with an owner and a date, kept with the meeting so its recap lists
# it: ours becomes work (a core todo), the client's a promise (Promise).
module AccountManagement
  class ActionItemsController < ApplicationController
    allow_staff
    agent_tool :add_meeting_action_item, on: :create, title: "Add an action item to a meeting",
      description: "owner is us or user:<id> (work on the client, or the meeting's engagement, led by that person or the meeting's owner) or client or contact:<id> (the client's promise). Listed in the recap.",
      params: { action_item: { description: "string!", owner: "string!", due_on: "date!" } }

    def create
      meeting = Meeting.find(params[:meeting_id])
      return redirect_to(account_management_meeting_path(meeting), alert: "The recap is out; add it as #{helpers.term(:work).downcase} on the #{helpers.term(:client).downcase} instead.") if meeting.recap_sent?

      attributes = params.expect(action_item: %i[description owner due_on])
      item = meeting.add_action_item!(**attributes.to_h.symbolize_keys)
      redirect_to account_management_meeting_path(meeting), notice: "Action item added: #{item.owner_name}, by #{l item.due_on, format: :short}."
    rescue ActiveRecord::RecordNotFound
      redirect_to account_management_meeting_path(meeting), alert: "That person or contact isn’t one to give it to."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to account_management_meeting_path(meeting), alert: e.record.errors.full_messages.to_sentence
    end
  end
end
