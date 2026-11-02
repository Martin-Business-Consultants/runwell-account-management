module AccountManagement
  # A call with a client, debriefed: its notes (a core call note), and what came out of it, each
  # linked here: work on the right engagements with owners, what the client promised, and requests
  # outside what its engagements cover (work nobody has taken on yet). Made in one go by record_call (Call::Plan), usually from an AI harness given the
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

    def todos = made("work")
    def promises = made("promise")
    def requests = made("request")

    def label = "#{CHANNELS.fetch(channel)} with #{client.name}, #{I18n.l happened_at, format: :short}"

    private
      def made(kind)
        loaded = items.loaded? ? items.select { it.kind == kind } : items.where(kind: kind).includes(:item)
        loaded.map(&:item).compact
      end
  end
end
