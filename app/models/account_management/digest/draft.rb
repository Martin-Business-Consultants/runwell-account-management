module AccountManagement
  # The first draft of a client's weekly digest, from what the client may see: work shared with
  # them that finished, meetings held and coming up, what we're waiting on them for, and what's
  # due next week. Nothing internal: work not shared with the client, notes and estimates stay out.
  class Digest::Draft
    include ActionView::Helpers::TagHelper, ActionView::Helpers::OutputSafetyHelper

    def initialize(client, week_of)
      @client, @week = client, week_of.all_week(:monday)
    end

    def to_html
      range = @week.first.beginning_of_day..@week.last.end_of_day
      finished = ::Todo.joins(:engagement).where(engagements: { client_id: @client.id }, client_visible: true, completed_at: range).order(:completed_at)
      held = Meeting.live.where(client: @client, starts_at: range).order(:starts_at)
      coming = Meeting.upcoming.where(client: @client, starts_at: ..(@week.last + 14).end_of_day)
      ours = @client.commitments.open.where(owner_kind: "us", due_on: (@week.last + 1)..(@week.last + 7)).ordered
      waiting = Waiting.for_client(@client)

      safe_join([
        tag.p("Here’s where things stand this week."),
        lines("Finished this week", finished.map(&:title)),
        lines("Meetings", held.map { "#{it.title}, #{it.when_label}" } + coming.map { "Coming up: #{it.title}, #{it.when_label}" }),
        lines("Waiting on you", waiting.map { "#{it.label} (#{it.detail})" }),
        lines("Next week from us", ours.map { "#{it.description}, by #{it.due_on.to_fs(:long)}" }),
        tag.p("Anything to add, or anything we’ve missed? Just reply.")
      ].compact)
    end

    private
      def lines(heading, items)
        return if items.empty?

        tag.p(tag.strong(heading)) + tag.ul(safe_join(items.map { tag.li(it) }))
      end
  end
end
