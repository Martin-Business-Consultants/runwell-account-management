module AccountManagement
  # What we're waiting on a client for: their overdue promises. Meeting agendas and call debriefs
  # read it.
  module Waiting
    extend self

    Item = Data.define(:record, :client, :label, :since, :detail) do
      def key = "waiting:#{record.class.name}:#{record.id}"
    end

    def items(client_ids)
      promises(client_ids)
    end

    def for_client(client) = items([ client.id ])

    private
      def promises(ids)
        Promise.overdue.where(client_id: ids).includes(:client, :contact).ordered.map do |promise|
          Item.new(promise, promise.client, promise.description, promise.due_on.in_time_zone,
            "theirs#{" (#{promise.contact.name})" if promise.contact}, due #{promise.due_on.to_fs(:long)}")
        end
      end
  end
end
