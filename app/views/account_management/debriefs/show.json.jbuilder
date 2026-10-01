data = @debrief.to_h
json.summary "Debrief a call with #{@client.name}: #{pluralize(data[:engagements].size, "open engagement")}, #{pluralize(data[:people].size, "person")} on the team. Follow steps, then record_call with preview: true."
json.client agent_ref(@client)
json.merge! data.except(:client)
json.lead data[:client][:lead]
json.backup data[:client][:backup]
json.brief @debrief.to_markdown
