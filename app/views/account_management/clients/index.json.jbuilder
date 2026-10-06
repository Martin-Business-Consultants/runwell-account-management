json.summary "#{pluralize(@clients.size, "client")}, #{@clients.count { @pulse.quiet?(it) }} quiet, #{@clients.count { %w[at_risk off_track].include?(@health[it.id]&.status) }} at risk or off track"
json.clients @clients do |client|
  lead = client.account_lead
  json.merge! agent_ref(client)
  json.health(@health[client.id]&.then { { status: it.status, reason: it.reason, week_of: it.week_of } })
  json.last_contact @pulse.last_contact(client)
  json.quiet @pulse.quiet?(client, lead)
  json.contact_every_days((lead&.contact_every || AccountManagement::Playbook::CONTACT_EVERY.days).in_days.round)
  json.lead agent_user(lead&.user)
  json.backup agent_user(lead&.backup_user)
  json.next_meeting(@next_meetings[client.id]&.then { { id: it.id, title: it.title, starts_at: it.starts_at } })
end
