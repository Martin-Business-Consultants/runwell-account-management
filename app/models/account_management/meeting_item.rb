module AccountManagement
  # An action item from a meeting: work we'll do (a core todo) or something the client promised
  # (a Promise), kept with the meeting so its recap lists it.
  class MeetingItem < ::ApplicationRecord
    belongs_to :meeting
    belongs_to :todo, class_name: "::Todo", optional: true
    belongs_to :promise, class_name: "AccountManagement::Promise", optional: true

    validate { errors.add(:base, "An action item is work or a promise") unless todo || promise }

    def record = todo || promise
    def ours? = todo.present?
    def description = todo ? todo.title : promise.description
    def due_on = todo ? todo.due_on : promise.due_on
    def owner_name = todo ? (todo.owner&.display_name || "Us") : promise.owner_name
    def open? = todo ? todo.status != "done" : promise.open?
    def overdue? = open? && due_on.present? && due_on < Date.current

    def state_label
      if open? then overdue? ? "Overdue" : "Open"
      else todo ? "Done" : promise.resolution.humanize
      end
    end
  end
end
