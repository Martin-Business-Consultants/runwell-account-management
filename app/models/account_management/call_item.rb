module AccountManagement
  # Something that came out of a call: a todo, a commitment or a request.
  class CallItem < ::ApplicationRecord
    belongs_to :call, class_name: "AccountManagement::Call"
    belongs_to :item, polymorphic: true
  end
end
