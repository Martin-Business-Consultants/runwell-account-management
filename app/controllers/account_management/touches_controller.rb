# The contact log: every call, email, text, chat or visit with a client, logged from the Contact
# quick action or the client's page.
module AccountManagement
  class TouchesController < ApplicationController
    allow_staff
    agent_tool :list_client_contacts, on: :index, title: "List logged client contacts",
      description: "Newest first, for one client (client_id) or every client you work with.", params: { client_id: "integer" }
    agent_tool :log_client_contact, on: :create, title: "Log a contact with a client",
      description: "record: \"Client:id\" or \"Engagement:id\". channel: call, email, text, chat, video or in_person; direction: out (we reached them) or in (they reached us); summary: what it was about; happened_on (a date, today by default); contact_id: who at the client. It counts as contact for the client's cadence, and an outbound one after a request answers it.",
      params: { record: "string!", touch: { channel: Touch::CHANNELS.keys, direction: Touch::DIRECTIONS.keys, summary: "text", happened_on: "date", contact_id: "integer" } }
    agent_tool :delete_client_contact, on: :destroy, title: "Delete a contact logged by mistake"

    def index
      scope = Touch.where(client_id: current_member.client_ids).includes(:client, :contact, :user).recent
      scope = scope.where(client_id: params[:client_id]) if params[:client_id].present?
      @touches = paginate scope
    end

    before_action :set_record, only: :create
    before_action :require_client_access, only: :create

    def create
      record = @record
      attributes = params.expect(touch: %i[channel direction summary happened_on contact_id])
      day = attributes.delete(:happened_on).presence&.then { Date.parse(it) } || Date.current
      touch = Touch.new(attributes.except(:contact_id).merge(client: @client, engagement: (record if record.is_a?(::Engagement)),
        contact: @client.contacts.find_by(id: attributes[:contact_id]), user: Member.person(Current.user),
        happened_at: day == Date.current ? Time.current : day.in_time_zone.change(hour: 12)))
      if touch.save
        touch.record_event!("account.contact_logged", payload: { what: touch.label })
        redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"), notice: "Logged: #{touch.label}."
      else
        redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"), alert: touch.errors.full_messages.to_sentence
      end
    rescue Date::Error
      redirect_back fallback_location: account_management_root_path, alert: "That date isn’t one I can read."
    end

    def destroy
      touch = Touch.find(params[:id])
      unless touch.user == Member.person(Current.user) || Current.user.can?(:delete_records)
        return redirect_back(fallback_location: account_management_touches_path, alert: "Only whoever logged it, or someone who may delete records, can delete it.")
      end

      touch.destroy!
      redirect_back fallback_location: client_path(touch.client, tab: "plugin-account_management"), notice: "Deleted."
    end

    private
      def set_record
        @record = QuickAction.locate(params[:record], Meeting::RECORD_TYPES) if params[:record].present?
        @client = @record.is_a?(::Engagement) ? @record.client : @record
        redirect_back(fallback_location: account_management_root_path, alert: "Choose the #{helpers.term(:client).downcase} it was with.") unless @client.is_a?(::Client)
      end
  end
end
