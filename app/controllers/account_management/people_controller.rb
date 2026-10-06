# The team's expertise, so work from a call goes to the right person. Set in Settings > Account
# management; debrief_call lists it with each person's open work.
module AccountManagement
  class PeopleController < ApplicationController
    skip_before_action :require_member
    allow_staff
    before_action :require_account_manager
    agent_tool :set_expertise, on: :update, title: "Set a person's expertise tags",
      description: "id: the person's user id. tags: e.g. code, design, content, seo, ads, social, analytics, email, strategy, ops (any word works). Needs manage_accounts.",
      params: { expertise: { tags: "string[]", note: "string" } }

    def update
      user = ::User.active.people.find(params[:id])
      attributes = params.require(:expertise).permit(:note, :tags, tags: [])
      expertise = Expertise.find_or_initialize_by(user: user)
      expertise.update!(tags: attributes[:tags], note: attributes[:note].presence)
      redirect_back fallback_location: account_management_settings_path, notice: "#{user.display_name}: #{expertise.tags.join(", ").presence || "no expertise"}."
    end
  end
end
