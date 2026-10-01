module AccountManagement
  # The standard a lead is held to. The scorecard measures against these, the playbook page
  # prints them, Today and home warn before each one is missed, and the guide explains them.
  module Playbook
    AGENDA_AHEAD = 24.hours     # an agenda goes out at least this long before the meeting
    RECAP_WITHIN = 24.hours     # a recap goes out within this long after it
    TOKEN_WARNING = 14.days     # home warns this long before a token expires
    VERIFY_EVERY = 90.days      # an access nobody has checked for this long is stale
    UPDATE_DAY = 5              # the weekly update is due by the end of Friday
    CONTACT_EVERY = 7           # days a client may go without hearing from us (a lead can change it per client)
    REPLY_WITHIN = 1            # business days to answer a client's request
    MEETING_GAP = 21.days       # a client with no meeting planned this far ahead, and no rhythm, is flagged
    WAITING_NUDGE = 3.days      # something we're waiting on the client for, this old, is worth a nudge
    HEALTH_DAY = 4              # each client's health is set by the end of Thursday, for Friday's update
    DIGEST_DAY = 5              # a client's weekly digest goes out by the end of Friday

    # Percent on time, per measure.
    TARGETS = { agendas: 100, recaps: 100, commitments: 95, updates: 100, replies: 95, contact: 100 }.freeze

    # The end of the business day after `time`: a request on Friday is due by the end of Monday.
    def self.reply_due_at(time)
      day = time.in_time_zone.to_date
      REPLY_WITHIN.times { day = day.next_day; day = day.next_day while day.on_weekend? }
      day.in_time_zone.end_of_day
    end

    Step = Data.define(:key, :label, :hint, :check)

    # What every client goes through on the way in and out. A step with a check ticks itself
    # off from the records; the rest a person ticks.
    CHECKLISTS = {
      "onboarding" => [
        Step.new(:lead, "Choose who leads it", "and a backup for when they’re out", ->(client) { client.account_lead.present? }),
        Step.new(:people, "Mark who’s who at the client", "at least the decision-maker and the day-to-day contact",
          ->(client) { ContactProfile.for_client(client).any? { it.roles.include?("decision_maker") } }),
        Step.new(:kickoff, "Hold the kickoff meeting", "with its recap sent", ->(client) { Meeting.where(client: client).where.not(recap_sent_at: nil).exists? }),
        Step.new(:rhythm, "Set a meeting rhythm", "weekly, every two weeks or monthly", ->(client) { MeetingSeries.active.where(client: client).exists? }),
        Step.new(:accounts, "Record their outside accounts", "pages, ad accounts, pixels, analytics, domains", ->(client) { Access.where(client: client).exists? }),
        Step.new(:access, "Get access to each account", "nothing left at none or requested",
          ->(client) { Access.where(client: client).exists? && !Access.where(client: client, our_access: %w[none requested]).exists? }),
        Step.new(:reporting, "Set up their reporting", "what they’ll see, and when", nil),
        Step.new(:welcome, "Send the welcome", "who to contact for what, and how fast we answer", nil)
      ],
      "offboarding" => [
        Step.new(:commitments, "Settle what’s open", "every commitment done or dropped", ->(client) { !client.commitments.open.exists? }),
        Step.new(:closed, "Close the work", "every engagement closed", ->(client) { !client.engagements.where(closed_at: nil).exists? }),
        Step.new(:rhythm, "Stop the meeting rhythm", nil, ->(client) { !MeetingSeries.active.where(client: client).exists? }),
        Step.new(:digest, "Stop the weekly digest", nil, ->(client) { !client.account_lead&.digest_enabled? }),
        Step.new(:handover, "Hand back their accounts", "they own each one, and our access is removed or agreed", nil),
        Step.new(:goodbye, "Have the goodbye call", "what went well, and whether they’d refer us", nil)
      ]
    }.freeze
  end
end
