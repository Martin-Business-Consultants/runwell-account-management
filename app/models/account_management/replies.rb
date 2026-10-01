module AccountManagement
  # A client's request is answered once it's triaged (in the core) or once we log a contact with
  # the client after it came in. It's due by the end of the next business day (Playbook).
  module Replies
    extend self

    # Open requests from these clients that nobody has answered.
    def waiting(client_ids)
      ::Request.open.where(client_id: client_ids, triaged_at: nil)
        .where.not(Touch.where(direction: "out").where("account_management_touches.client_id = requests.client_id")
          .where("account_management_touches.happened_at >= requests.received_at").arel.exists)
        .includes(:client).order(:received_at)
    end

    def due_at(request) = Playbook.reply_due_at(request.received_at)
    def late?(request) = Time.current > due_at(request)

    # When it was answered: triaged, or our first contact with the client after it came in.
    def answered_at(request)
      contact = Touch.where(client_id: request.client_id, direction: "out", happened_at: request.received_at..).minimum(:happened_at)
      [ request.triaged_at, contact ].compact.min
    end
  end
end
