module AccountManagement
  # A client's weekly digest: the client-facing half of the week (what we finished, meetings, what
  # we're waiting on them for, what's next), for clients whose lead switched it on. Drafted from
  # the records, finished by a person, and final once sent; due by the end of Friday.
  class Digest < ::ApplicationRecord
    belongs_to :client, class_name: "::Client"
    belongs_to :sent_by, class_name: "::User", optional: true

    validates :week_of, uniqueness: { scope: :client_id }

    scope :sent, -> { where.not(sent_at: nil) }

    def self.week_of(date = Date.current) = date.beginning_of_week(:monday)

    def self.for_week(client, week = week_of)
      find_or_initialize_by(client: client, week_of: week).tap { it.body ||= Draft.new(client, week).to_html }
    end

    def sent? = sent_at.present?
    def due_at = (week_of + (Playbook::DIGEST_DAY - 1)).in_time_zone.end_of_day
    def label = "Week of #{week_of.to_fs(:long)}"

    def send!(contacts:, actor: Current.user)
      raise ArgumentError, "This digest is already out." if sent?
      raise ArgumentError, "Write the digest first." if ActionController::Base.helpers.strip_tags(body.to_s).squish.blank?

      contacts = Array(contacts)
      raise ArgumentError, "Choose who it goes to." if contacts.empty?

      transaction do
        update!(sent_at: Time.current, sent_by: actor, sent_to: contacts.map(&:name).to_sentence)
        contacts.each { Touch.create!(client: client, contact: it, user: actor, subject: self, channel: "email", direction: "out", source: "digest", happened_at: Time.current, summary: "Weekly digest") }
        client.record_event!("account.digest_sent", actor: actor, payload: { week: label, to: sent_to })
      end
      contacts.each { ClientMailer.with(contact: it, subject: "#{client.name}: your week with us", body: body, reply_to: Member.person(actor)&.email_address).letter.deliver_later }
    end
  end
end
