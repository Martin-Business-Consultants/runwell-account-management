module AccountManagement
  # A client's meeting rhythm: weekly, every two weeks or monthly (the same weekday of the month,
  # e.g. the second Tuesday), from a first date. The next meeting always exists: when the series
  # starts, and each night after one has happened, the following one is planned (ensure_next!).
  # Each is an ordinary meeting, with its agenda due a day ahead.
  class MeetingSeries < ::ApplicationRecord
    self.table_name = "account_management_meeting_series"

    CADENCES = { "weekly" => "Every week", "biweekly" => "Every two weeks", "monthly" => "Every month" }.freeze

    belongs_to :client, class_name: "::Client"
    belongs_to :engagement, class_name: "::Engagement", optional: true
    belongs_to :owner, class_name: "::User", optional: true
    belongs_to :created_by, class_name: "::User", optional: true
    has_many :meetings, class_name: "AccountManagement::Meeting", foreign_key: :series_id, inverse_of: :series, dependent: :nullify

    validates :title, :starts_on, presence: true
    validates :cadence, inclusion: { in: CADENCES.keys }
    validates :time_of_day, format: { with: /\A\d{1,2}:\d{2}\z/ }

    scope :active, -> { where(active: true) }

    def cadence_label = CADENCES.fetch(cadence)

    def label
      day = starts_on.strftime("%A")
      every = case cadence
      when "monthly" then "the #{(starts_on.day - 1) / 7 + 1}#{%w[st nd rd th th][(starts_on.day - 1) / 7]} #{day} of each month"
      when "biweekly" then "every other #{day}"
      else "every #{day}"
      end
      "#{every} at #{Time.zone.parse(time_of_day).strftime("%-l:%M %p")}"
    end

    # The occurrence on or after a date.
    def next_on(from = Date.current)
      date = starts_on
      date = following(date) while date < from
      date
    end

    # Plans the next meeting when none is coming up. Returns it, or nil.
    def ensure_next!
      return unless active?
      return if meetings.upcoming.exists?

      last = meetings.maximum(:starts_at)&.to_date
      date = next_on(last ? following(last) : [ starts_on, Date.current ].max)
      hour, minute = time_of_day.split(":").map(&:to_i)
      meeting = meetings.create!(client: client, engagement: engagement, owner: owner || client.account_lead&.user, created_by: created_by,
        title: title, starts_at: Time.zone.local(date.year, date.month, date.day, hour, minute))
      meeting.record_event!("meeting.planned", actor: nil, source: "rhythm", payload: { starts_at: meeting.starts_at.iso8601 })
      meeting
    end

    def stop!
      transaction do
        update!(active: false)
        meetings.upcoming.where(agenda_sent_at: nil).find_each { it.cancel!(actor: Current.user) }
      end
    end

    private
      def following(date)
        case cadence
        when "weekly" then date + 7
        when "biweekly" then date + 14
        else nth_weekday(date.next_month.beginning_of_month, starts_on.wday, (starts_on.day - 1) / 7)
        end
      end

      # The nth (0-based) weekday of a month, or its last one when the month is short of it.
      def nth_weekday(month_start, wday, nth)
        first = month_start + ((wday - month_start.wday) % 7)
        date = first + nth * 7
        date.month == month_start.month ? date : date - 7
      end
  end
end
