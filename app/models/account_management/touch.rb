module AccountManagement
  # One contact with a client: a call, an email, a text, a chat, a visit. Logged by hand from the
  # Contact quick action or the client's tab, or by a call debrief. With meetings, notes, requests
  # and approvals it tells when the client last heard from us (Pulse).
  class Touch < ::ApplicationRecord
    include ::Eventful

    CHANNELS = { "call" => "Call", "email" => "Email", "text" => "Text", "chat" => "Chat", "video" => "Video call", "in_person" => "In person" }.freeze
    DIRECTIONS = { "out" => "We reached out", "in" => "They reached us" }.freeze

    belongs_to :client, class_name: "::Client"
    belongs_to :engagement, class_name: "::Engagement", optional: true
    belongs_to :contact, class_name: "::Contact", optional: true
    belongs_to :user, class_name: "::User", optional: true
    belongs_to :subject, polymorphic: true, optional: true

    validates :channel, inclusion: { in: CHANNELS.keys }
    validates :direction, inclusion: { in: DIRECTIONS.keys }
    validates :happened_at, presence: true
    validate :contact_belongs_to_client

    scope :recent, -> { order(happened_at: :desc) }

    def channel_label = CHANNELS.fetch(channel)
    def outbound? = direction == "out"

    def label
      who = contact&.name || client.name
      outbound? ? "#{channel_label} to #{who}" : "#{channel_label} from #{who}"
    end

    private
      def contact_belongs_to_client
        errors.add(:contact, "must be at the #{::Client.model_name.human.downcase}") if contact && contact.client_id != client_id
      end
  end
end
