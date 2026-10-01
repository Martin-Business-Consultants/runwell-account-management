json.summary "#{pluralize(@touches.size, "contact")} logged"
json.contacts @touches do |touch|
  json.id touch.id
  json.client agent_ref(touch.client)
  json.label touch.label
  json.channel touch.channel
  json.direction touch.direction
  json.source touch.source
  json.summary touch.summary
  json.happened_at touch.happened_at
  json.by agent_user(touch.user)
end
