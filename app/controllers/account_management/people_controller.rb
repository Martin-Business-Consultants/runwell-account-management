# The team's expertise, so work from a call goes to the right person: tags per person, with what
# each has open and leads.
module AccountManagement
  class PeopleController < ApplicationController
    allow_staff
    before_action :require_account_manager, only: :update
    agent_tool :list_team_expertise, on: :index, title: "List the team with their expertise and open work"
    agent_tool :set_expertise, on: :update, title: "Set a person's expertise tags",
      description: "id: the person's user id. tags: e.g. code, design, content, seo, ads, social, analytics, email, strategy, ops (any word works). Needs manage_accounts.",
      params: { expertise: { tags: "string[]", note: "string" } }

    def index
      @people = ::User.active.people.ordered.to_a
      @expertise = Expertise.where(user: @people).index_by(&:user_id)
      @open_work = ::Todo.where.not(status: "done").where(owner: @people).group(:owner_id).count
      @leads = Lead.where(user: @people).group(:user_id).count
      @members = Member.where(user: @people).pluck(:user_id).to_set
    end

    def update
      user = ::User.active.people.find(params[:id])
      attributes = params.require(:expertise).permit(:note, :tags, tags: [])
      expertise = Expertise.find_or_initialize_by(user: user)
      expertise.update!(tags: attributes[:tags], note: attributes[:note].presence)
      redirect_back fallback_location: account_management_people_path, notice: "#{user.display_name}: #{expertise.tags.join(", ").presence || "no expertise"}."
    end
  end
end
