module AccountManagement
  # The standard a lead is held to. Today and home warn before each one is missed, and the guide
  # explains them.
  module Playbook
    AGENDA_AHEAD = 24.hours     # an agenda goes out at least this long before the meeting
    RECAP_WITHIN = 24.hours     # a recap goes out within this long after it
    CONTACT_EVERY = 7           # days a client may go without hearing from us (a lead can change it per client)
    REPLY_WITHIN = 1            # business days to answer a client's request
    MEETING_GAP = 21.days       # a client with no meeting planned this far ahead, and no rhythm, is flagged
    HEALTH_DAY = 4              # each client's health is set by the end of Thursday

    # The end of the business day after `time`: a request on Friday is due by the end of Monday.
    def self.reply_due_at(time)
      day = time.in_time_zone.to_date
      REPLY_WITHIN.times { day = day.next_day; day = day.next_day while day.on_weekend? }
      day.in_time_zone.end_of_day
    end
  end
end
