module AccountManagement
  # What a person is good at, as tags (code, design, seo…), so work from a call goes to the right
  # owner. Any tag can be used; SUGGESTED are offered first. Set on Accounts > People.
  class Expertise < ::ApplicationRecord
    SUGGESTED = %w[code design content seo ads social analytics email strategy ops].freeze

    belongs_to :user, class_name: "::User"

    before_validation { self.tags = self.class.normalize(tags) }

    def self.normalize(value)
      list = value.is_a?(String) ? value.split(/[,\n]/) : Array(value)
      list.map { it.to_s.strip.downcase.gsub(/[^a-z0-9 _-]/, "").squish.tr(" ", "-") }.compact_blank.uniq.first(12)
    end

    # { user_id => [tags] }
    def self.tags_by_user = all.to_h { [ it.user_id, it.tags ] }

    # Every tag in use, suggested ones first.
    def self.vocabulary = (SUGGESTED + all.flat_map(&:tags)).uniq
  end
end
