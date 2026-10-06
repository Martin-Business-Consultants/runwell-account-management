module AccountManagement
  # What we're waiting on a client for: their overdue commitments and agreements sent and not yet
  # decided. Meeting agendas and call debriefs read it.
  module Waiting
    extend self

    Item = Data.define(:record, :client, :label, :since, :detail) do
      def key = "waiting:#{record.class.name}:#{record.id}"
    end

    def items(client_ids)
      commitments(client_ids) + approvals(client_ids)
    end

    def for_client(client) = items([ client.id ])

    private
      def commitments(ids)
        ::Commitment.overdue.where(owner_kind: "client", client_id: ids).includes(:client, :contact).ordered.map do |commitment|
          Item.new(commitment, commitment.client, commitment.description, commitment.due_on.in_time_zone,
            "theirs#{" (#{commitment.contact.name})" if commitment.contact}, due #{commitment.due_on.to_fs(:long)}")
        end
      end

      def approvals(ids)
        ::AgreementVersion.joins(:engagement).where(engagements: { client_id: ids }).where.not(sent_at: nil)
          .where(superseded_by_id: nil).where.missing(:approval).includes(engagement: :client).map do |version|
          Item.new(version, version.engagement.client, "Decision on #{version.engagement.title} (#{version.label.downcase})", version.sent_at,
            "sent #{version.sent_at.to_date.to_fs(:long)}, not yet decided")
        end
      end
  end
end
