module AccountManagement
  # The one person who answers for a client: its meetings, its commitments and its health. Also
  # where the client's account settings live: a backup who covers while the lead is away, and how
  # often the client should hear from us.
  class Lead < ::ApplicationRecord
    belongs_to :client, class_name: "::Client"
    belongs_to :user, class_name: "::User"
    belongs_to :backup_user, class_name: "::User", optional: true

    validates :client_id, uniqueness: true
    validates :contact_every_days, numericality: { only_integer: true, in: 1..90 }, allow_nil: true
    validate :backup_differs

    # The clients a person leads.
    def self.clients_for(user) = ::Client.where(id: where(user: user).select(:client_id))

    # Who acts for the client today: the lead, or their backup while they're away.
    def responsible_user
      lead_member = Member.for(user)
      lead_member&.away? && backup_user ? backup_user : user
    end

    def covering? = responsible_user != user

    def contact_every = (contact_every_days || Playbook::CONTACT_EVERY).days

    private
      def backup_differs
        errors.add(:backup_user, "can’t be the lead") if backup_user_id.present? && backup_user_id == user_id
      end
  end
end
