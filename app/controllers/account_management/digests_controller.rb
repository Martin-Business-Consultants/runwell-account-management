# This week's digest for a client: drafted from what the client may see, edited, then sent.
module AccountManagement
  class DigestsController < ApplicationController
    allow_staff
    before_action :set_client
    before_action :require_client_access
    before_action { @digest = Digest.for_week(@client) }
    agent_tool :show_client_digest, on: :show, title: "Show this week's digest for a client",
      description: "The draft (from finished client-visible work, meetings, what we're waiting on them for and next week's commitments) or what was sent, and who it goes to."
    agent_tool :update_client_digest, on: :update, title: "Change this week's digest before it's sent", params: { digest: { body: "text" } }
    agent_tool :send_client_digest, on: :deliver, title: "Send this week's digest to the client",
      description: "contact_ids: who it goes to (the decision-makers and day-to-day contacts by default). Final once sent; it counts as contact.",
      params: { contact_ids: "integer[]" }, confirm: "It emails the client's contacts this week's digest."

    def show
      @recipients = ContactProfile.recipients(@client)
    end

    def update
      return redirect_to(account_management_client_digest_path(@client), alert: "This digest is already out.") if @digest.sent?

      @digest.update!(body: params.dig(:digest, :body))
      redirect_to account_management_client_digest_path(@client), notice: "Saved."
    end

    def deliver
      contacts = @client.contacts.active.where(id: Array(params[:contact_ids]).compact_blank).where.not(email: [ nil, "" ]).to_a
      @digest.save! if @digest.new_record?
      @digest.send!(contacts: contacts)
      redirect_to account_management_client_digest_path(@client), notice: "Sent to #{@digest.sent_to}."
    rescue ArgumentError => error
      redirect_to account_management_client_digest_path(@client), alert: error.message
    end
  end
end
