module AccountManagement
  # An item on someone's Today list, set aside until a time. It comes back on its own.
  class Snooze < ::ApplicationRecord
    CHOICES = { "1" => "Tomorrow", "3" => "In 3 days", "7" => "Next week" }.freeze

    belongs_to :user, class_name: "::User"

    scope :current, -> { where(until: Time.current..) }

    def self.keys_for(user) = current.where(user: user).pluck(:item_key).to_set
  end
end
