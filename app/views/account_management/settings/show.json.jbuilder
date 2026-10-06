json.summary "Account management is on for #{pluralize(@members.size, "person")}"
json.members @members do |member|
  json.id member.id
  json.user agent_user(member.user)
  json.clients member.all_clients? ? "all" : member.clients.map { agent_ref(it) }
  json.away_until member.away_until
end
json.can_switch_on(@others.map { agent_user(it) })
json.expertise(@expertise.map { |user_id, tags| { user_id: user_id, tags: tags } })
