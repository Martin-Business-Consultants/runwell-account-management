module AccountManagement
  # A client's request (work they asked for that nobody has taken on: Todo.requests with someone
  # who asked) is answered once someone takes it on, or once we log a contact with the client
  # after it came in. It's due by the end of the next business day (Playbook).
  module Replies
    extend self

    # What clients asked for: work with a contact or a sender, however it came in.
    def asked(client_ids) = ::Todo.where(client_id: client_ids).where("todos.contact_id IS NOT NULL OR todos.sender_email IS NOT NULL")

    # Requests from these clients that nobody has answered.
    def waiting(client_ids)
      asked(client_ids).requests
        .where.not(Touch.where(direction: "out").where("account_management_touches.client_id = todos.client_id")
          .where("account_management_touches.happened_at >= todos.created_at").arel.exists)
        .includes(:client, :contact).order(:created_at)
    end

    def due_at(request) = Playbook.reply_due_at(request.created_at)
    def late?(request) = Time.current > due_at(request)

    # When it was answered: our first contact with the client after it came in.
    def answered_at(request)
      Touch.where(client_id: request.client_id, direction: "out", happened_at: request.created_at..).minimum(:happened_at)
    end
  end
end
