json.summary "#{@meeting.title}, #{@meeting.when_label}: #{@meeting.state.humanize.downcase}; agenda #{account_paper_line(@meeting, :agenda).downcase}; recap #{account_paper_line(@meeting, :recap).downcase}"
json.partial! "account_management/meetings/meeting", meeting: @meeting
json.agenda agent_text(@meeting.agenda)
json.recap agent_text(@meeting.recap)
json.action_items @meeting.action_items do |item|
  json.merge! agent_ref(item.todo) if item.todo
  json.whose item.ours? ? "ours" : "theirs"
  json.extract! item, :description, :due_on, :owner_name, :state_label
end
json.recipients(@meeting.recipients.map { { "id" => it.id, "name" => it.name, "email" => it.email } })
