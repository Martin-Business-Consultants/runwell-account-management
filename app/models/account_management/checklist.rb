module AccountManagement
  # A client's onboarding or offboarding (Playbook::CHECKLISTS), started by whoever looks after it.
  # Steps with a check tick themselves from the records; the others are ticked here, with who
  # and when. Complete once every step is done.
  class Checklist < ::ApplicationRecord
    KINDS = { "onboarding" => "Onboarding", "offboarding" => "Offboarding" }.freeze

    StepState = Data.define(:step, :done, :done_at, :done_by, :automatic) do
      delegate :key, :label, :hint, to: :step
    end

    belongs_to :client, class_name: "::Client"
    belongs_to :started_by, class_name: "::User", optional: true

    validates :kind, inclusion: { in: KINDS.keys }, uniqueness: { scope: :client_id }

    scope :unfinished, -> { where(finished_at: nil) }

    def label = KINDS.fetch(kind)

    def steps
      @steps ||= Playbook::CHECKLISTS.fetch(kind).map do |step|
        if step.check
          StepState.new(step, step.check.call(client), nil, nil, true)
        else
          entry = done[step.key.to_s]
          StepState.new(step, entry.present?, entry&.dig("at")&.then { Time.zone.parse(it) }, entry&.dig("by"), false)
        end
      end
    end

    def reload(*)
      @steps = nil
      super
    end

    def done_count = steps.count(&:done)
    def complete? = steps.all?(&:done)

    def toggle!(key, user:)
      step = Playbook::CHECKLISTS.fetch(kind).find { it.key.to_s == key.to_s } or raise ArgumentError, "No step #{key}."
      raise ArgumentError, "That step ticks itself from the records." if step.check

      entries = done.dup
      entries.key?(step.key.to_s) ? entries.delete(step.key.to_s) : entries[step.key.to_s] = { "at" => Time.current.iso8601, "by" => user.display_name }
      update!(done: entries)
      @steps = nil
      settle!
    end

    # Stamps it finished once every step is done (or reopens it if one comes undone).
    def settle!
      complete? ? (finished_at || update!(finished_at: Time.current)) : (finished_at && update!(finished_at: nil))
    end
  end
end
