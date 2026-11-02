json.summary "#{@call.label}: #{pluralize(@call.todos.size, "todo")}, #{pluralize(@call.promises.size, "promise")} of theirs, #{pluralize(@call.requests.size, "request")}"
json.id @call.id
json.client agent_ref(@client)
json.summary_line @call.summary
json.happened_at @call.happened_at
json.channel @call.channel
json.notes agent_text(@call.note&.body)
json.todos @call.todos do |todo|
  json.merge! agent_ref(todo)
  json.engagement todo.engagement&.ref
  json.owner agent_user(todo.owner)
  json.due_on todo.due_on
  json.status todo.status
end
json.promises @call.promises do |promise|
  json.extract! promise, :id, :description, :due_on, :resolution
  json.by promise.owner_name
end
json.requests @call.requests do |request|
  json.merge! agent_ref(request)
  json.taken_on !request.request?
end
