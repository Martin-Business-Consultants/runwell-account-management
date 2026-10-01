module AccountManagement
  # What a debriefed call will make, checked as a whole before anything is written: the call
  # (its notes become a core call note, and a contact), work on the client's open engagements
  # with an owner each, commitments (ours with a person, theirs with a contact), requests for
  # anything outside the agreed scope, and this week's health. `preview` says what would be made,
  # by name, with every problem; `apply!` makes it all in one transaction, or nothing.
  class Call::Plan
    attr_reader :client, :user, :errors, :warnings

    def initialize(client:, user:, params:)
      @client, @user = client, user
      @params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      @errors, @warnings = [], []
      @todos = list(:todos).each_with_index.map { |todo, index| check_todo(todo, index + 1) }
      @commitments = list(:commitments).each_with_index.map { |commitment, index| check_commitment(commitment, index + 1) }
      @requests = list(:requests).each_with_index.map { |request, index| check_request(request, index + 1) }
      check_call
      check_health
    end

    def valid? = errors.empty?

    def preview
      {
        call: { summary: summary, channel: channel, happened_on: happened_at.to_date, meeting: @meeting&.label, with: contacts.map(&:name) },
        todos: @todos.map { { engagement: it[:engagement]&.ref, title: it[:title], owner: it[:owner]&.display_name, due_on: it[:due_on], scope_item: it[:scope_item]&.description, client_visible: it[:client_visible] } },
        commitments: @commitments.map { { description: it[:description], owner: it[:owner_kind] == "us" ? it[:user]&.display_name : (it[:contact]&.name || client.name), owner_kind: it[:owner_kind], due_on: it[:due_on], engagement: it[:engagement]&.ref } },
        requests: @requests.map { { subject: it[:subject] } },
        health: health && { status: health[:status], reason: health[:reason] },
        errors: errors,
        warnings: warnings
      }
    end

    def summary_line
      parts = [ ("#{@todos.size} #{"todo".pluralize(@todos.size)}#{owners_line}" if @todos.any?),
                ("#{@commitments.size} #{"commitment".pluralize(@commitments.size)}" if @commitments.any?),
                ("#{@requests.size} #{"request".pluralize(@requests.size)}" if @requests.any?),
                ("health #{HealthCheck::STATUSES[health[:status]].downcase}" if health) ].compact
      parts.any? ? parts.to_sentence : "the notes only"
    end

    def apply!
      raise ArgumentError, errors.to_sentence unless valid?

      ActiveRecord::Base.transaction do
        note = client.notes.create!(kind: "call", body: notes.presence || summary, author: user, occurred_at: happened_at, source: Current.source || "app")
        call = Call.create!(client: client, meeting: @meeting, note: note, user: Member.person(user), channel: channel, summary: summary, happened_at: happened_at)
        Touch.create!(client: client, contact: contacts.first, user: Member.person(user), subject: call, channel: channel, direction: "out", source: "call", summary: summary, happened_at: happened_at)
        @todos.each { call.items.create!(item: make_todo(it, call)) }
        @commitments.each { call.items.create!(item: make_commitment(it)) }
        @requests.each { call.items.create!(item: make_request(it)) }
        HealthCheck.record!(client: client, status: health[:status], reason: health[:reason], user: Member.person(user)) if health
        client.record_event!("account.call_recorded", payload: { call: summary, made: summary_line })
        call
      end
    end

    private
      def list(key) = Array(@params[key.to_s]).map { it.respond_to?(:to_h) ? it.to_h.stringify_keys : {} }
      def call_params = (@params["call"] || {}).to_h.stringify_keys

      def summary = call_params["summary"].to_s.strip
      def notes = call_params["notes"].to_s
      def channel = call_params["channel"].presence_in(Call::CHANNELS.keys) || "call"
      def happened_at = @happened_at ||= (date(call_params["happened_on"], "The call’s date") || Date.current).then { it == Date.current ? Time.current : it.in_time_zone.change(hour: 12) }
      def contacts = @contacts ||= client.contacts.active.where(id: Array(call_params["contact_ids"]).compact_blank).to_a

      def health
        return @health if defined?(@health)

        given = (@params["health"] || {}).to_h.stringify_keys
        @health = given["status"].present? ? { status: given["status"], reason: given["reason"].presence } : nil
      end

      def owners_line
        counts = @todos.filter_map { it[:owner]&.display_name }.tally
        counts.any? ? " (#{counts.map { |name, count| "#{name} #{count}" }.join(", ")})" : ""
      end

      def check_call
        errors << "Say what the call was about in call.summary" if summary.blank?
        if (id = call_params["meeting_id"]).present?
          @meeting = Meeting.where(client: client).find_by(id: id) or errors << "Meeting #{id} isn’t one of #{client.name}’s"
        end
        happened_at
      end

      def check_health
        return unless health

        errors << "health.status must be one of #{HealthCheck::STATUSES.keys.join(", ")}" unless HealthCheck::STATUSES.key?(health[:status])
        errors << "health.reason is needed unless it’s on track" if health[:status] != "on_track" && health[:reason].blank?
      end

      def check_todo(todo, n)
        where = "Todo #{n}"
        engagement = engagement_for(todo["engagement"], where, required: true)
        owner = person(todo["owner_id"], "#{where}: owner_id")
        errors << "#{where} needs an owner_id: the person who’ll do it" if todo["owner_id"].blank?
        errors << "#{where} needs a title" if todo["title"].blank?
        scope_item = nil
        if todo["scope_item_id"].present? && engagement
          scope_item = ::ScopeItem.joins(:agreement_version).find_by(id: todo["scope_item_id"], agreement_versions: { engagement_id: engagement.id }) or
            errors << "#{where}: scope item #{todo["scope_item_id"]} isn’t on #{engagement.ref}"
        end
        { engagement: engagement, owner: owner, scope_item: scope_item, title: todo["title"].to_s.strip, description: todo["description"].presence,
          due_on: date(todo["due_on"], "#{where}: due_on"), client_visible: ActiveModel::Type::Boolean.new.cast(todo["client_visible"]) || false }
      end

      def check_commitment(commitment, n)
        where = "Commitment #{n}"
        kind = commitment["owner_kind"].presence_in(::Commitment::OWNER_KINDS) || (errors << "#{where}: owner_kind is us or client" and nil)
        owner = kind == "us" ? person(commitment["user_id"], "#{where}: user_id") : nil
        errors << "#{where}: ours needs a user_id, who’ll keep it" if kind == "us" && commitment["user_id"].blank?
        contact = nil
        if kind == "client" && commitment["contact_id"].present?
          contact = client.contacts.active.find_by(id: commitment["contact_id"]) or errors << "#{where}: contact #{commitment["contact_id"]} isn’t at #{client.name}"
        end
        errors << "#{where} needs a description" if commitment["description"].blank?
        due = date(commitment["due_on"], "#{where}: due_on")
        errors << "#{where} needs a due_on: a commitment has a date" if commitment["due_on"].blank?
        { description: commitment["description"].to_s.strip, owner_kind: kind, user: owner, contact: contact, due_on: due,
          engagement: engagement_for(commitment["engagement"], where, required: false) }
      end

      def check_request(request, n)
        errors << "Request #{n} needs a subject" if request["subject"].blank?
        { subject: request["subject"].to_s.strip, body: request["body"].presence }
      end

      def engagement_for(ref, where, required:)
        if ref.blank?
          errors << "#{where} needs an engagement: the ref of the #{client.name} engagement it belongs to" if required
          return
        end
        engagement = client.engagements.find_by(ref: ref.to_s.upcase) or return (errors << "#{where}: #{ref} isn’t one of #{client.name}’s engagements" and nil)
        errors << "#{where}: #{engagement.ref} is closed" if engagement.closed?
        engagement
      end

      def person(id, where)
        return if id.blank?

        found = ::User.active.people.find_by(id: id) or return (errors << "#{where}: nobody active has id #{id}" and nil)
        member = Member.for(found)
        warnings << "#{found.display_name} is away until #{member.away_until.to_fs(:long)}" if member&.away?
        found
      end

      def date(value, where)
        return if value.blank?

        Date.parse(value.to_s)
      rescue Date::Error
        errors << "#{where} isn’t a date (YYYY-MM-DD)"
        nil
      end

      def make_todo(line, call)
        description = [ line[:description], "<p>From the #{Call::CHANNELS.fetch(channel).downcase} with #{ERB::Util.h(client.name)} on #{happened_at.to_date.to_fs(:long)}: #{ERB::Util.h(summary)}.</p>" ].compact.join
        todo = line[:engagement].todos.create!(title: line[:title], description: description, owner: line[:owner], due_on: line[:due_on],
          scope_item: line[:scope_item], client_visible: line[:client_visible], created_by: user)
        todo.record_event!("todo.created", payload: { from: call.label })
        todo
      end

      def make_commitment(line)
        commitment = client.commitments.create!(description: line[:description], owner_kind: line[:owner_kind], user: line[:user], contact: line[:contact],
          due_on: line[:due_on], engagement: line[:engagement], source: "call: #{summary}".truncate(250))
        commitment.record_event!("commitment.added", payload: { call: summary })
        @meeting.items.create!(commitment: commitment) if @meeting
        commitment
      end

      def make_request(line)
        request = ::Request.create!(client: client, contact: contacts.first, sender_name: contacts.first&.name || client.name, sender_email: contacts.first&.email,
          subject: line[:subject], body: line[:body], source: "call", received_at: happened_at)
        request.record_event!("request.received", payload: { source: "call" }) if request.respond_to?(:record_event!)
        request
      end
  end
end
