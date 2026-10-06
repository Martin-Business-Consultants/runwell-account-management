module AccountManagement
  # When each client last heard from us, or we from them, from everything that counts as
  # contact: logged contacts, meetings held, agendas and recaps sent, call / meeting / email
  # notes, requests they sent, and agreements sent and their decisions. Internal notes don't
  # count. A client is quiet once that's older than its lead's contact cadence.
  class Pulse
    def initialize(client_ids)
      @client_ids = Array(client_ids)
    end

    # { client_id => time of last contact }
    def last_contacts
      @last_contacts ||= sources.each_with_object({}) do |(relation, client_column, time_column), last|
        relation.group(client_column).maximum(time_column).each { |client_id, time| last[client_id] = [ last[client_id], time ].compact.max if time }
      end
    end

    def last_contact(client) = last_contacts[client.id]

    def quiet?(client, lead = client.account_lead)
      every = lead&.contact_every || Playbook::CONTACT_EVERY.days
      last = last_contact(client)
      last ? last < every.ago : client.created_at < every.ago
    end

    # Days until the cadence runs out (negative once it has).
    def days_left(client, lead = client.account_lead)
      every = lead&.contact_every || Playbook::CONTACT_EVERY.days
      last = last_contact(client) || client.created_at
      ((last + every - Time.current) / 1.day).floor
    end

    private
      # Each source of contact: a relation, its client column and its time column.
      def sources
        ids = @client_ids
        versions = ::AgreementVersion.joins(:engagement).where(engagements: { client_id: ids })
        [
          [ Touch.where(client_id: ids), "account_management_touches.client_id", "account_management_touches.happened_at" ],
          [ Meeting.live.where(client_id: ids, starts_at: ..Time.current), "account_management_meetings.client_id", "account_management_meetings.starts_at" ],
          [ Meeting.where(client_id: ids), "account_management_meetings.client_id", "account_management_meetings.agenda_sent_at" ],
          [ Meeting.where(client_id: ids), "account_management_meetings.client_id", "account_management_meetings.recap_sent_at" ],
          [ ::Note.where(subject_type: "Client", subject_id: ids).where.not(kind: "internal"), "notes.subject_id", "notes.occurred_at" ],
          [ ::Note.where(subject_type: "Engagement").where.not(kind: "internal").joins("INNER JOIN engagements ON engagements.id = notes.subject_id")
              .where(engagements: { client_id: ids }), "engagements.client_id", "notes.occurred_at" ],
          [ ::Request.where(client_id: ids), "requests.client_id", "requests.received_at" ],
          [ versions, "engagements.client_id", "agreement_versions.sent_at" ],
          [ ::Approval.joins(agreement_version: :engagement).where(engagements: { client_id: ids }), "engagements.client_id", "approvals.decided_at" ]
        ]
      end
  end
end
