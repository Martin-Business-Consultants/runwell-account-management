module AccountManagement
  # A meeting's first agenda from the records, for the client's eyes: what's still open from last
  # time, what we owe and what they owe, decisions waiting on them, and what's coming up. And the
  # recap's skeleton after: the agenda's points, then decisions and action items to fill in.
  class Meeting::AgendaDraft
    include ActionView::Helpers::TagHelper, ActionView::Helpers::OutputSafetyHelper

    def initialize(meeting)
      @meeting = meeting
      @client = meeting.client
    end

    def agenda_html
      previous = Meeting.live.where(client: @client).where(starts_at: ...@meeting.starts_at).where.not(id: @meeting.id).order(starts_at: :desc).first
      from_last = previous ? previous.commitments.open.ordered : ::Commitment.none
      ours = @client.commitments.open.where(owner_kind: "us").where.not(id: from_last.select(:id)).where(due_on: ..(@meeting.starts_at.to_date + 14)).ordered
      theirs = @client.commitments.open.where(owner_kind: "client").where.not(id: from_last.select(:id)).ordered
      decisions = Waiting.for_client(@client).select { it.record.is_a?(::AgreementVersion) }
      scoped = @meeting.engagement ? [ @meeting.engagement ] : @client.engagements.where(closed_at: nil).to_a
      next_up = ::Todo.where(engagement: scoped, client_visible: true, completed_at: nil).where(due_on: ..(@meeting.starts_at.to_date + 14)).order(:due_on)

      safe_join([
        lines("Open from last time#{" (#{previous.when_label})" if previous}", from_last.map { "#{it.description} (#{owner(it)}, due #{it.due_on.to_fs(:long)})" }),
        lines("From us", ours.map { "#{it.description}, due #{it.due_on.to_fs(:long)}" }),
        lines("From you", theirs.map { "#{it.description}, due #{it.due_on.to_fs(:long)}" }),
        lines("Decisions we need", decisions.map(&:label)),
        lines("Coming up", next_up.map { "#{it.title}#{", due #{it.due_on.to_fs(:long)}" if it.due_on}" }),
        tag.p(tag.strong("Anything else"))
      ].compact)
    end

    def recap_html
      safe_join([
        tag.p(tag.strong("Decisions")), tag.ul(tag.li("…")),
        tag.p(tag.strong("Discussed")),
        (@meeting.agenda.present? ? ActionController::Base.helpers.sanitize(@meeting.agenda) : tag.ul(tag.li("…"))),
        tag.p("Action items, with who and by when, are listed below.")
      ])
    end

    private
      def owner(commitment) = commitment.owner_kind == "us" ? "us" : (commitment.contact&.name || "you")

      def lines(heading, items)
        return if items.empty?

        tag.p(tag.strong(heading)) + tag.ul(safe_join(items.map { tag.li(it) }))
      end
  end
end
