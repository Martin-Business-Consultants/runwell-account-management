module AccountManagement
  # One client a member chose to work with.
  class MemberClient < ::ApplicationRecord
    belongs_to :member, class_name: "AccountManagement::Member"
    belongs_to :client, class_name: "::Client"
  end
end
