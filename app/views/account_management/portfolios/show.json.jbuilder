json.summary current_member.all_clients? ? "You work with every client" : "You work with #{pluralize(current_member.clients.count, "client")}"
json.client_scope current_member.client_scope
json.clients(current_member.clients.ordered.map { agent_ref(it) })
json.away_until current_member.away_until
