module AccountManagement
  # Someone's Today list across the clients they work with, most urgent first: what's overdue,
  # what's due today, what's coming this week, and what to keep an eye on. Items they've snoozed
  # wait until their time. Each item says what it is, which client, and where to act on it.
  class Cockpit
    URGENCIES = { overdue: "Overdue", today: "Today", week: "This week", watch: "Keep an eye on" }.freeze

    Item = Data.define(:key, :urgency, :kind, :title, :detail, :path, :client, :mine) do
      def snoozable? = urgency != :overdue || kind != :meeting
    end

    def initialize(user, member: Member.for(user), helpers: Rails.application.routes.url_helpers)
      @user, @member, @routes = user, member, helpers
    end

    def clients = @clients ||= @member ? @member.clients.ordered.includes(:account_lead).to_a : []
    def client_ids = @client_ids ||= clients.map(&:id)
    def pulse = @pulse ||= Pulse.new(client_ids)
    def health = @health ||= HealthCheck.latest_for(client_ids)

    def items
      @items ||= begin
        snoozed = Snooze.keys_for(@user)
        all = meetings + replies + commitments + quiet + health_items + rhythm
        all.reject { snoozed.include?(it.key) }.sort_by { [ URGENCIES.keys.index(it.urgency), it.mine ? 0 : 1 ] }
      end
    end

    def snoozed_count = Snooze.current.where(user: @user).count
    def by_urgency = items.group_by(&:urgency)

    private
      def mine?(client) = (lead = client.account_lead) ? lead.responsible_user == @user : false

      def item(key, urgency, kind, title, detail, path, client)
        Item.new(key, urgency, kind, title, detail, path, client, client ? mine?(client) : true)
      end

      def meetings
        upcoming = Meeting.live.where(client_id: client_ids).where(starts_at: Time.current.beginning_of_day..7.days.from_now).includes(:client)
        owed = Meeting.needing_recap.where(client_id: client_ids, starts_at: 30.days.ago..).includes(:client)
        (upcoming.to_a + owed.to_a).uniq.filter_map do |meeting|
          path = @routes.account_management_meeting_path(meeting)
          case meeting.state
          when "recap_due"
            item("recap:#{meeting.id}", meeting.recap_late? ? :overdue : :today, :meeting, "Send the recap: #{meeting.title}", meeting.when_label, path, meeting.client)
          when "agenda_due"
            item("agenda:#{meeting.id}", meeting.agenda_late? ? :overdue : :today, :meeting, "Send the agenda: #{meeting.title}", "#{meeting.when_label}, due by #{I18n.l meeting.agenda_due_at, format: :short}", path, meeting.client)
          when "planned"
            today = meeting.starts_at.to_date == Date.current
            item("meeting:#{meeting.id}", today ? :today : :week, :meeting, "#{today ? "Today" : "Coming up"}: #{meeting.title}", meeting.when_label, path, meeting.client)
          end
        end
      end

      def replies
        Replies.waiting(client_ids).map do |request|
          late = Replies.late?(request)
          item("reply:#{request.id}", late ? :overdue : :today, :request, "Answer: #{request.subject}",
            "from #{request.sender_name.presence || request.client.name}, #{late ? "was due" : "due"} by #{I18n.l Replies.due_at(request), format: :short}",
            @routes.request_path(request), request.client)
        end
      end

      def commitments
        ::Commitment.open.where(owner_kind: "us", client_id: client_ids).where(due_on: ..(Date.current + 7)).includes(:client).ordered.map do |commitment|
          urgency = commitment.due_on < Date.current ? :overdue : (commitment.due_on == Date.current ? :today : :week)
          item("commitment:#{commitment.id}", urgency, :commitment, commitment.description, "ours, due #{commitment.due_on.to_fs(:long)}",
            @routes.client_path(commitment.client, tab: "commitments"), commitment.client)
        end
      end

      def quiet
        clients.filter_map do |client|
          left = pulse.days_left(client)
          next if left > 2

          last = pulse.last_contact(client)
          item("quiet:#{client.id}", left.negative? ? :overdue : :week, :quiet, left.negative? ? "Get in touch with #{client.name}" : "Check in with #{client.name} soon",
            last ? "last contact #{ActionController::Base.helpers.time_ago_in_words(last)} ago" : "no contact yet",
            @routes.client_path(client, tab: "plugin-account_management"), client)
        end
      end


      def health_items
        week = HealthCheck.week_of
        due = Date.current >= week + (Playbook::HEALTH_DAY - 1)
        clients.filter_map do |client|
          check = health[client.id]
          path = @routes.client_path(client, tab: "plugin-account_management")
          if due && client.account_lead && (check.nil? || check.week_of < week)
            item("health:#{client.id}:#{week}", :week, :health, "How is #{client.name} doing this week?", "set its health by the end of Thursday", path, client)
          elsif check && check.status != "on_track"
            item("risk:#{client.id}:#{check.week_of}", check.status == "off_track" ? :today : :watch, :health, "#{client.name} is #{check.label.downcase}", check.reason, path, client)
          end
        end
      end

      def rhythm
        planned = Meeting.upcoming.where(client_id: client_ids, starts_at: ..Playbook::MEETING_GAP.from_now).distinct.pluck(:client_id).to_set
        with_series = MeetingSeries.active.where(client_id: client_ids).distinct.pluck(:client_id).to_set
        clients.reject { planned.include?(it.id) || with_series.include?(it.id) }.select(&:account_lead).map do |client|
          item("rhythm:#{client.id}", :watch, :meeting, "No meeting planned with #{client.name}", "set a rhythm, or plan the next one",
            @routes.client_path(client, tab: "plugin-account_management"), client)
        end
      end
  end
end
