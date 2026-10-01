json.summary "A nudge to #{@client.name}: #{@title}"
json.client agent_ref(@client)
json.to(@recipients.map { { id: it.id, name: it.name, email: it.email } })
json.title @title
json.body agent_text(@body)
