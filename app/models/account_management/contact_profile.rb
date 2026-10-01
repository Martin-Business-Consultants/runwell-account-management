module AccountManagement
  # Who a client's contact is to us: the decision-maker, the day-to-day contact, who pays,
  # who's technical, and how they'd rather hear from us. Agendas, recaps, nudges and digests go to
  # the decision-maker and day-to-day contacts first.
  class ContactProfile < ::ApplicationRecord
    ROLES = { "decision_maker" => "Decision-maker", "day_to_day" => "Day-to-day", "billing" => "Billing", "technical" => "Technical" }.freeze
    CHANNELS = { "email" => "Email", "phone" => "Phone", "text" => "Text", "chat" => "Chat", "meeting" => "Meetings" }.freeze

    belongs_to :contact, class_name: "::Contact"

    validates :preferred_channel, inclusion: { in: CHANNELS.keys }, allow_nil: true
    validate :known_roles

    before_validation { self.roles = Array(roles).compact_blank.uniq & ROLES.keys }

    def self.for_client(client) = where(contact_id: client.contacts.active.select(:id))

    # Who papers and nudges go to by default: the decision-makers and day-to-day contacts with an
    # email, or every active contact with one when nobody is marked.
    def self.recipients(client)
      with_email = client.contacts.active.where.not(email: [ nil, "" ]).ordered
      marked = with_email.where(id: for_client(client).select { (it.roles & %w[decision_maker day_to_day]).any? }.map(&:contact_id))
      marked.exists? ? marked : with_email
    end

    def role_labels = roles.map { ROLES.fetch(it) }
    def channel_label = CHANNELS[preferred_channel]

    private
      def known_roles
        errors.add(:roles, "has an unknown role") unless roles.all? { ROLES.key?(it) }
      end
  end
end
