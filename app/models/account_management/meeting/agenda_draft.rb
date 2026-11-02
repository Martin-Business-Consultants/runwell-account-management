module AccountManagement
  # A meeting's first agenda from the records, for the client's eyes: what's still open from last
  # time, what we'll deliver soon (work they can see) and what they promised. And the recap's
  # skeleton after: the agenda's points, then decisions and action items to fill in.
  class Meeting::AgendaDraft
    include ActionView::Helpers::TagHelper, ActionView::Helpers::OutputSafetyHelper

    def initialize(meeting)
      @meeting = meeting
      @client = meeting.client
    end

    def agenda_html
      previous = Meeting.live.where(client: @client).where(starts_at: ...@meeting.starts_at).where.not(id: @meeting.id).order(starts_at: :desc).first
      from_last = previous ? previous.action_items.select(&:open?) : []
      last_todos = from_last.filter_map(&:todo).map(&:id)
      last_promises = from_last.filter_map(&:promise).map(&:id)
      work = @meeting.engagement ? ::Todo.where(engagement: @meeting.engagement) : ::Todo.where(client: @client)
      ours = work.open.client_visible.where.not(id: last_todos).where(due_on: ..(@meeting.starts_at.to_date + 14)).order(:due_on)
      theirs = Promise.open.where(client: @client).where.not(id: last_promises).ordered

      safe_join([
        lines("Open from last time#{" (#{previous.when_label})" if previous}", from_last.map { "#{it.description} (#{it.ours? ? "us" : it.owner_name}#{", due #{it.due_on.to_fs(:long)}" if it.due_on})" }),
        lines("From us", ours.map { "#{it.title}, due #{it.due_on.to_fs(:long)}" }),
        lines("From you", theirs.map { "#{it.description}, due #{it.due_on.to_fs(:long)}" }),
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
      def lines(heading, items)
        return if items.empty?

        tag.p(tag.strong(heading)) + tag.ul(safe_join(items.map { tag.li(it) }))
      end
  end
end
