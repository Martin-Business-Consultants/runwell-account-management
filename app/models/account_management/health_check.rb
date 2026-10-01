module AccountManagement
  # How a client stands this week, set by whoever looks after it by the end of Thursday: on
  # track, at risk, or off track, with a one-line reason. One per client per week; the latest is
  # its current health, and the weeks make its trend.
  class HealthCheck < ::ApplicationRecord
    STATUSES = { "on_track" => "On track", "at_risk" => "At risk", "off_track" => "Off track" }.freeze
    RISK = { "off_track" => 0, "at_risk" => 1, "on_track" => 2 }.freeze

    belongs_to :client, class_name: "::Client"
    belongs_to :user, class_name: "::User", optional: true

    validates :status, inclusion: { in: STATUSES.keys }
    validates :reason, presence: true, unless: -> { status == "on_track" }
    validates :week_of, uniqueness: { scope: :client_id }

    scope :recent, -> { order(week_of: :desc) }

    def self.week_of(date = Date.current) = date.beginning_of_week(:monday)

    # { client_id => its latest check }
    def self.latest_for(client_ids)
      where(id: where(client_id: client_ids).group(:client_id).select("MAX(id)")).index_by(&:client_id)
    end

    def self.record!(client:, status:, reason:, user:)
      check = find_or_initialize_by(client: client, week_of: week_of)
      check.update!(status: status, reason: reason.presence, user: user)
      client.record_event!("account.health_set", payload: { status: check.label, reason: check.reason })
      check
    end

    def label = STATUSES.fetch(status)
    def this_week? = week_of == self.class.week_of
  end
end
