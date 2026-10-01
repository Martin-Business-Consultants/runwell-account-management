json.summary "#{@call.label}: #{pluralize(@call.todos.size, "todo")}, #{pluralize(@call.commitments.size, "commitment")}, #{pluralize(@call.requests.size, "request")}"
json.id @call.id
json.client agent_ref(@client)
json.summary_line @call.summary
json.happened_at @call.happened_at
json.channel @call.channel
json.notes agent_text(@call.note&.body)
json.todos @call.todos do |todo|
  json.merge! agent_ref(todo)
  json.engagement todo.engagement.ref
  json.owner agent_user(todo.owner)
  json.due_on todo.due_on
  json.status todo.status
end
json.commitments @call.commitments do |commitment|
  json.merge! agent_ref(commitment)
  json.owner_kind commitment.owner_kind
  json.owner agent_user(commitment.user)
  json.due_on commitment.due_on
end
json.requests(@call.requests.map { agent_ref(it) })
