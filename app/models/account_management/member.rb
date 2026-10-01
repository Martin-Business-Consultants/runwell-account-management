module AccountManagement
  # Someone account management is switched on for (Settings > Account management): a project
  # manager who looks after clients. Each works with every client, or a group they choose; the
  # clients they lead or back up are always theirs. While away, their clients' warnings go to
  # each client's backup.
  class Member < ::ApplicationRecord
    SCOPES = { "all" => "Every client", "selected" => "The clients I choose" }.freeze

    belongs_to :user, class_name: "::User"
    belongs_to :activated_by, class_name: "::User", optional: true
    has_many :member_clients, class_name: "AccountManagement::MemberClient", dependent: :delete_all
    has_many :chosen_clients, through: :member_clients, source: :client

    validates :client_scope, inclusion: { in: SCOPES.keys }

    scope :ordered, -> { joins(:user).merge(::User.ordered) }

    def self.for(user)
      return if user.nil?

      find_by(user: person(user))
    end

    def self.active?(user) = self.for(user).present?

    # The person behind a user: an agent acts for its person.
    def self.person(user) = user.respond_to?(:agent?) && user.agent? ? user.agent_owner : user

    def all_clients? = client_scope == "all"
    def away? = away_until.present? && away_until >= Date.current

    # The clients this person works with: everyone, or those they chose plus those they lead or
    # back up.
    def clients
      return ::Client.active if all_clients?

      ::Client.active.where(id: member_clients.select(:client_id))
        .or(::Client.active.where(id: Lead.where(user_id: user_id).or(Lead.where(backup_user_id: user_id)).select(:client_id)))
    end

    def client_ids = clients.ids

    def choose!(scope:, client_ids: [])
      transaction do
        update!(client_scope: scope)
        member_clients.delete_all
        ::Client.where(id: client_ids).find_each { member_clients.create!(client: it) } if scope == "selected"
      end
    end
  end
end
