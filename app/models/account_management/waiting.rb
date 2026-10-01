module AccountManagement
  # What we're waiting on a client for: their overdue commitments, agreements sent and not yet
  # decided, and access we've asked for and don't have. Each can be nudged (NudgesController),
  # which emails the right people and logs the contact.
  module Waiting
    extend self

    Item = Data.define(:record, :client, :label, :since, :detail) do
      def key = "waiting:#{record.class.name}:#{record.id}"
      def nudgeable? = since <= Playbook::WAITING_NUDGE.ago
    end

    def items(client_ids)
      commitments(client_ids) + approvals(client_ids) + accesses(client_ids)
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

      def accesses(ids)
        Access.where(client_id: ids, our_access: "requested").includes(:client).map do |access|
          Item.new(access, access.client, "Access to #{access.platform_label} #{access.name}", access.updated_at, "requested, not granted yet")
        end
      end
  end
end
