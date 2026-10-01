# A nudge: an email to the client about something we're waiting on them for (an overdue
# commitment of theirs, a decision on an agreement, access we asked for), previewed first and
# logged as contact.
module AccountManagement
  class NudgesController < ApplicationController
    allow_staff
    before_action :set_subject
    before_action :require_client_access
    agent_tool :preview_nudge, on: :new, title: "Preview a nudge to a client",
      description: "subject: \"Commitment:id\", \"AgreementVersion:id\" or \"Access:id\", from show_account_today's waiting items. Shows who it goes to and the message.",
      params: { subject: "string!" }
    agent_tool :send_nudge, on: :create, title: "Send a nudge to a client",
      description: "subject as for preview_nudge; contact_ids (the decision-makers and day-to-day contacts by default), and the message's title and body, edited if you like. It's logged as contact.",
      params: { subject: "string!", contact_ids: [ "integer" ], nudge: { title: "string", body: "text" } }, confirm: "It emails the client's contacts."

    def new
      @recipients = ContactProfile.recipients(@client)
      @title, @body = default_message
    end

    def create
      contacts = @client.contacts.active.where(id: Array(params[:contact_ids]).compact_blank).where.not(email: [ nil, "" ]).to_a
      return redirect_to(new_account_management_nudge_path(subject: params[:subject]), alert: "Choose who it goes to.") if contacts.empty?

      title, body = default_message
      title = params.dig(:nudge, :title).presence || title
      body = params.dig(:nudge, :body).presence || body
      person = Member.person(Current.user)
      Touch.transaction do
        contacts.each { Touch.create!(client: @client, contact: it, user: person, subject: @subject, channel: "email", direction: "out", source: "nudge", happened_at: Time.current, summary: title) }
        @client.record_event!("account.nudged", payload: { about: title, to: contacts.map(&:name).to_sentence })
      end
      contacts.each { ClientMailer.with(contact: it, subject: title, body: body, reply_to: person&.email_address).letter.deliver_later }
      redirect_to account_management_root_path, notice: "Nudged #{contacts.map(&:name).to_sentence} about #{title.downcase_first}."
    end

    private
      SUBJECTS = %w[Commitment AgreementVersion AccountManagement::Access].freeze

      def set_subject
        type, id = params[:subject].to_s.split(":", 2)
        type = "AccountManagement::Access" if type == "Access"
        return head(:not_found) unless SUBJECTS.include?(type)

        @subject = type.constantize.find(id)
        @client = @subject.is_a?(::AgreementVersion) ? @subject.engagement.client : @subject.client
      end

      def default_message
        case @subject
        when ::Commitment
          [ "Following up: #{@subject.description}",
            "<p>We’re waiting on <strong>#{ERB::Util.h(@subject.description)}</strong>, which was due #{@subject.due_on.to_fs(:long)}. Could you let us know when we can expect it, or if anything’s in the way?</p>" ]
        when ::AgreementVersion
          [ "Your decision on #{@subject.engagement.title}",
            "<p>We sent <strong>#{ERB::Util.h(@subject.engagement.title)}</strong> (#{ERB::Util.h(@subject.label.downcase)}) for your approval on #{@subject.sent_at.to_date.to_fs(:long)}. When you have a moment, please approve it or tell us what to change, using the link in that email.</p>" ]
        else
          [ "Access to #{@subject.platform_label} #{@subject.name}",
            "<p>We asked for access to <strong>#{ERB::Util.h(@subject.platform_label)} #{ERB::Util.h(@subject.name)}</strong> and it hasn’t come through yet. Could you add us, or tell us who can?</p>" ]
        end
      end
  end
end
