json.summary "#{@client.name}'s digest for the #{@digest.label.downcase_first}: #{@digest.sent? ? "sent to #{@digest.sent_to}" : "not sent"}"
json.client agent_ref(@client)
json.week_of @digest.week_of
json.sent_at @digest.sent_at
json.sent_to @digest.sent_to
json.to(@recipients.map { { id: it.id, name: it.name, email: it.email } })
json.body agent_text(@digest.body)
