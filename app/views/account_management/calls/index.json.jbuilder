json.summary "#{pluralize(@calls.size, "call")} debriefed"
json.calls @calls do |call|
  json.id call.id
  json.client agent_ref(call.client)
  json.summary call.summary
  json.happened_at call.happened_at
  json.todos call.items.where(item_type: "Todo").count
  json.by agent_user(call.user)
end
