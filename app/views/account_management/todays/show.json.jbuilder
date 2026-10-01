json.summary @cockpit.items.empty? ? "Nothing needs you across #{pluralize(@cockpit.clients.size, "client")}" : "#{pluralize(@cockpit.items.size, "item")} across #{pluralize(@cockpit.clients.size, "client")}: " +
  AccountManagement::Cockpit::URGENCIES.filter_map { |key, label| (count = @cockpit.items.count { it.urgency == key }).positive? ? "#{count} #{label.downcase}" : nil }.join(", ").presence.to_s
json.items @cockpit.items do |item|
  json.key item.key
  json.urgency item.urgency
  json.kind item.kind
  json.title item.title
  json.detail item.detail
  json.client agent_ref(item.client)
  json.url item.path
  json.yours item.mine
end
json.snoozed @cockpit.snoozed_count
