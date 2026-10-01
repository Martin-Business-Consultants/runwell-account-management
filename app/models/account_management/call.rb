module AccountManagement
  # A call with a client, debriefed: its notes (a core call note), and what came out of it, each
  # linked here: work on the right engagements with owners, commitments, and requests outside the
  # agreed scope. Made in one go by record_call (Call::Plan), usually from an AI harness given the
  # notes, after the person has seen the plan.
  class Call < ::ApplicationRecord
    CHANNELS = Touch::CHANNELS.slice("call", "video", "in_person")

    belongs_to :client, class_name: "::Client"
    belongs_to :meeting, class_name: "AccountManagement::Meeting", optional: true
    belongs_to :note, class_name: "::Note", optional: true
    belongs_to :user, class_name: "::User", optional: true
    has_many :items, class_name: "AccountManagement::CallItem", dependent: :delete_all

    validates :summary, :happened_at, presence: true
    validates :channel, inclusion: { in: CHANNELS.keys }

    scope :recent, -> { order(happened_at: :desc) }

    def todos = items.where(item_type: "Todo").includes(:item).map(&:item).compact
    def commitments = items.where(item_type: "Commitment").includes(:item).map(&:item).compact
    def requests = items.where(item_type: "Request").includes(:item).map(&:item).compact

    def label = "#{CHANNELS.fetch(channel)} with #{client.name}, #{I18n.l happened_at, format: :short}"
  end
end
