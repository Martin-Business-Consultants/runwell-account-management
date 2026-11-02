module AccountManagement
  # Something that came out of a call: work (a todo with an owner), a request (a todo nobody has
  # taken on yet) or a client's promise. `kind` says which, since a request stops being one once
  # someone takes it on.
  class CallItem < ::ApplicationRecord
    KINDS = %w[work request promise].freeze

    belongs_to :call, class_name: "AccountManagement::Call"
    belongs_to :item, polymorphic: true
  end
end
