json.summary "#{pluralize(@people.size, "person")}, #{@expertise.count { |_, e| e.tags.any? }} with expertise set"
json.people @people do |person|
  json.merge! agent_user(person)
  json.role person.role
  json.expertise @expertise[person.id]&.tags || []
  json.note @expertise[person.id]&.note
  json.open_work @open_work.fetch(person.id, 0)
  json.leads @leads.fetch(person.id, 0)
  json.account_management @members.include?(person.id)
end
