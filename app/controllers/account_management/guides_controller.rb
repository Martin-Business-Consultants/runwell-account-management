# How account management works, for whoever's using it: the guide.
module AccountManagement
  class GuidesController < ApplicationController
    skip_before_action :require_member
    allow_staff
    agent_exempt :show, reason: "the user guide; the tools' descriptions say the same"

    def show
    end
  end
end
