module AccountManagement
  # Everything needed to turn a client call's notes into work, for an AI harness (debrief_call) or
  # to paste into one (Copy for AI on the client's tab): the client's people, its open engagements
  # with their agreed scope and current work, a meeting the call may have been, what we're waiting
  # on them for, the team with each person's expertise, open work and whether they're away, and
  # how to choose an engagement and an owner for each item.
  class Debrief
    STEPS = <<~TEXT
      1. Read the notes. List every concrete action: things we'll do (todos), dated promises (commitments), new asks (requests), and how the client is doing (health).
      2. Each todo goes on the open engagement whose agreed scope covers it (match its scope items; pass scope_item_id when one fits). Something nobody agreed to is a request, not a todo.
      3. Give each todo an owner by expertise: the person whose tags fit the work (code, design, seo, ads…). Among equals, the one with less open work. Client-facing or coordinating work goes to the client's lead. Never someone who's away. If nobody fits, the lead, and say so.
      4. Commitments: what the client promised (owner_kind client, contact_id when it's one person) and dated promises we made to them (owner_kind us, user_id). Every commitment has a due_on.
      5. Due dates only when the notes give or clearly imply one. client_visible only for work the client should see in their portal.
      6. Call record_call with preview: true and show the person the plan as a short table (engagement, todo, owner, due). Change what they say, then call record_call without preview. It records the notes as a call note, logs the contact and makes everything at once.
    TEXT

    def initialize(client)
      @client = client
    end

    def to_h
      {
        client: { id: @client.id, name: @client.name, lead: person_ref(lead&.user), backup: person_ref(lead&.backup_user) },
        contacts: contacts,
        engagements: engagements,
        meetings: meetings,
        waiting_on_them: Waiting.for_client(@client).map { { label: it.label, detail: it.detail } },
        people: people,
        steps: STEPS,
        record_call_example: example
      }
    end

    def to_markdown
      data = to_h
      lines = [ "# Debrief a call with #{@client.name}", "" ]
      lines << "Lead: #{data[:client][:lead]&.dig(:name) || "nobody"}#{" · backup: #{data[:client][:backup][:name]}" if data[:client][:backup]}"
      lines << "" << "## How to do it" << "" << STEPS << "## Their people" << ""
      data[:contacts].each { lines << "- #{it[:name]} (contact_id #{it[:id]})#{", can approve" if it[:can_approve]}" }
      lines << "" << "## Open engagements" << ""
      data[:engagements].each do |engagement|
        lines << "### #{engagement[:ref]} #{engagement[:title]} (#{engagement[:label]}, #{engagement[:state]})" << ""
        lines << "Agreed scope:" if engagement[:scope].any?
        engagement[:scope].each { lines << "- #{it[:description]} (scope_item_id #{it[:id]})" }
        lines << "" << "Open work:" if engagement[:open_work].any?
        engagement[:open_work].each { lines << "- #{it[:title]}: #{it[:owner] || "nobody"}, #{it[:status]}#{", due #{it[:due_on]}" if it[:due_on]}" }
        lines << ""
      end
      if data[:meetings].any?
        lines << "## Meetings around now (pass meeting_id if the call was one)" << ""
        data[:meetings].each { lines << "- #{it[:title]}, #{it[:when]} (meeting_id #{it[:id]})" }
        lines << ""
      end
      if data[:waiting_on_them].any?
        lines << "## Waiting on them" << ""
        data[:waiting_on_them].each { lines << "- #{it[:label]} (#{it[:detail]})" }
        lines << ""
      end
      lines << "## The team (owner_id / user_id)" << ""
      data[:people].each do |person|
        notes = [ (person[:expertise].any? ? person[:expertise].join(", ") : "no expertise set"), "#{person[:open_work]} open", ("leads this client" if person[:leads]),
                  ("backs it up" if person[:backup]), ("away until #{person[:away_until]}" if person[:away_until]) ].compact
        lines << "- #{person[:name]} (#{person[:id]}, #{person[:role]}): #{notes.join(" · ")}"
      end
      lines << "" << "## record_call" << "" << "```json" << JSON.pretty_generate(data[:record_call_example]) << "```" << ""
      lines.join("\n")
    end

    private
      def lead = @lead ||= @client.account_lead

      def person_ref(user) = user && { id: user.id, name: user.display_name }

      def contacts
        @client.contacts.active.ordered.map { { id: it.id, name: it.name, email: it.email, can_approve: it.can_approve? } }
      end

      def engagements
        @client.engagements.where(closed_at: nil).includes(:todos, agreement_versions: %i[scope_items approval]).order(:ref).map do |engagement|
          open = engagement.todos.reject { it.status == "done" }.sort_by { [ it.due_on || Date.new(9999), it.id ] }
          { ref: engagement.ref, title: engagement.title, label: engagement.label, shape: engagement.shape, state: engagement.state,
            scope: engagement.agreed_items.map { { id: it.id, description: it.description } },
            open_work: open.first(25).map { { id: it.id, title: it.title, owner: it.owner&.display_name, status: it.status, due_on: it.due_on } } }
        end
      end

      def meetings
        Meeting.live.where(client: @client, starts_at: 2.days.ago..1.day.from_now).order(:starts_at).map { { id: it.id, title: it.title, when: it.when_label } }
      end

      def people
        expertise = Expertise.tags_by_user
        open_work = ::Todo.where.not(status: "done").where.not(owner_id: nil).group(:owner_id).count
        members = Member.all.index_by(&:user_id)
        ::User.active.people.ordered.map do |user|
          member = members[user.id]
          { id: user.id, name: user.display_name, role: user.role, expertise: expertise.fetch(user.id, []), open_work: open_work.fetch(user.id, 0),
            leads: lead&.user_id == user.id, backup: lead&.backup_user_id == user.id, away_until: (member.away_until if member&.away?) }.compact
        end
      end

      def example
        engagement = @client.engagements.where(closed_at: nil).first
        {
          call: { summary: "Weekly check-in", happened_on: Date.current, channel: "call", contact_ids: [ @client.contacts.active.first&.id ].compact, notes: "<the notes, as given>" },
          todos: [ { engagement: engagement&.ref || "P-1", title: "…", owner_id: lead&.user_id || 0, due_on: Date.current + 7, scope_item_id: nil, client_visible: false }.compact ],
          commitments: [ { description: "Send the new logo files", owner_kind: "client", due_on: Date.current + 3 } ],
          requests: [ { subject: "Wants a landing page for the spring sale", body: "…" } ],
          health: { status: "on_track" },
          preview: true
        }
      end
  end
end
