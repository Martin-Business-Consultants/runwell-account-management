module AccountManagement
  # What account management puts on a person's home page before a standard is missed, for people
  # it's switched on for: agendas due and recaps owed, their weekly update, clients who haven't
  # heard from us, requests past their reply time, health to set on Thursday, digests to send on
  # Friday, and accounts we can't get into. Each client's items go to whoever acts for it today:
  # its lead, or the backup while the lead is away. A client without a lead goes to whoever may
  # manage accounts. Today (Cockpit) has the rest.
  module Attention
    extend self

    def items(user)
      return [] unless Member.active?(user)

      meetings(user) + updates(user) + quiet(user) + replies(user) + health(user) + digests(user) + accesses(user) + unled_clients(user)
    end

    def responsible?(user, meeting)
      return meeting.owner == user if meeting.owner && !Member.for(meeting.owner)&.away?

      lead = meeting.client.account_lead
      lead ? lead.responsible_user == user : user.can?(:manage_accounts)
    end

    # The clients a person acts for today: those they lead and aren't away from, and those whose
    # lead is away and they back up.
    def acting_for(user)
      Lead.where(user: user).or(Lead.where(backup_user: user)).includes(:client, :user, :backup_user)
        .select { it.responsible_user == user }.map(&:client).select { it.status == "active" }
    end

    # This week's from Friday, and last week's if it never went out.
    def updates(user)
      return [] unless WeeklyUpdate.owed_by?(user)

      this_week = WeeklyUpdate.week_of
      weeks = [ this_week - 7 ]
      weeks << this_week if Date.current >= this_week + (Playbook::UPDATE_DAY - 1)
      weeks.filter_map do |week|
        update = user.weekly_updates.find_or_initialize_by(week_of: week)
        update unless update.sent? || (week < this_week && !Lead.where(user: user).where(created_at: ..update.due_at).exists?)
      end
    end

    private
      def meetings(user)
        agendas = Meeting.needing_agenda.includes(:owner, client: :account_lead).select { it.state == "agenda_due" }
        recaps = Meeting.needing_recap.where(starts_at: 30.days.ago..).includes(:owner, client: :account_lead)
        (agendas + recaps.to_a).select { responsible?(user, it) }
      end

      def quiet(user)
        clients = acting_for(user)
        pulse = Pulse.new(clients.map(&:id))
        clients.select { pulse.quiet?(it) }.map { Alert.new(it, :quiet, "hasn’t heard from us in #{pulse.last_contact(it) ? ActionController::Base.helpers.time_ago_in_words(pulse.last_contact(it)) : "a while"}") }
      end

      def replies(user)
        Replies.waiting(acting_for(user).map(&:id)).select { Replies.late?(it) || Replies.due_at(it) < 4.hours.from_now }
      end

      def health(user)
        week = HealthCheck.week_of
        return [] unless Date.current >= week + (Playbook::HEALTH_DAY - 1)

        clients = acting_for(user)
        set = HealthCheck.where(client: clients, week_of: week).pluck(:client_id).to_set
        clients.reject { set.include?(it.id) }.map { Alert.new(it, :health, "set its health for this week") }
      end

      def digests(user)
        week = Digest.week_of
        return [] unless Date.current >= week + (Playbook::DIGEST_DAY - 1)

        clients = acting_for(user).select { it.account_lead.digest_enabled? }
        sent = Digest.sent.where(client: clients, week_of: week).pluck(:client_id).to_set
        clients.reject { sent.include?(it.id) }.map { Alert.new(it, :digest, "send its weekly digest today") }
      end

      # Only what stops work or is about to: ownership, access and tokens. Stale checks wait in
      # the register.
      def accesses(user)
        led = acting_for(user).map(&:id)
        scope = user.can?(:manage_accounts) ? Access.where(client_id: led).or(Access.where.not(client_id: Lead.select(:client_id))) : Access.where(client_id: led)
        scope.includes(:client).ordered.select { urgent?(it) }
      end

      def urgent?(access)
        %w[third_party unknown].include?(access.owned_by) || %w[none requested].include?(access.our_access) || access.token_problem
      end

      def unled_clients(user)
        return [] unless user.can?(:manage_accounts)

        ::Client.active.where.not(id: Lead.select(:client_id)).ordered.to_a
      end
  end
end
