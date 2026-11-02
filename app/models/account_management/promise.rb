module AccountManagement
  # Something a client said they'd do by a date ("send the new logo files by Friday"): from a
  # meeting's action items or a debriefed call. The core keeps only our side (work with a due
  # date), so the client's side lives here. Waiting reads the overdue ones; agendas list the open.
  class Promise < ::ApplicationRecord
    RESOLUTIONS = %w[done missed dropped].freeze

    belongs_to :client, class_name: "::Client"
    belongs_to :engagement, class_name: "::Engagement", optional: true
    belongs_to :contact, class_name: "::Contact", optional: true
    belongs_to :created_by, class_name: "::User", optional: true

    validates :description, :due_on, presence: true
    validates :resolution, inclusion: { in: RESOLUTIONS }, allow_nil: true
    validate :contact_belongs_to_client

    scope :open, -> { where(resolution: nil) }
    scope :overdue, -> { open.where(due_on: ...Date.current) }
    scope :ordered, -> { order(:due_on) }

    def open? = resolution.nil?
    def overdue? = open? && due_on < Date.current
    def owner_name = contact&.name || client.name

    def resolve!(resolution)
      raise ArgumentError, "already resolved" unless open?

      update!(resolution: resolution.to_s, resolved_at: Time.current)
    end

    private
      def contact_belongs_to_client
        errors.add(:contact, "must be at #{client.name}") if contact && client && contact.client_id != client_id
      end
  end
end
