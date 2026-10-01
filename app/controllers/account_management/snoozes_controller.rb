# Setting an item on Today aside for a day, three days or a week, or bringing it back.
module AccountManagement
  class SnoozesController < ApplicationController
    allow_staff
    agent_tool :snooze_today_item, on: :create, title: "Snooze an item on Today",
      description: "key: the item's key from show_account_today; days: 1, 3 or 7.", params: { key: "string!", days: Snooze::CHOICES.keys }
    agent_tool :unsnooze_today_item, on: :destroy, title: "Bring a snoozed item back (or every one, without a key)", params: { key: "string" }

    def create
      days = params[:days].presence_in(Snooze::CHOICES.keys) || "1"
      snooze = Snooze.find_or_initialize_by(user: Current.user, item_key: params.require(:key))
      snooze.update!(until: days.to_i.days.from_now.beginning_of_day + 6.hours)
      redirect_back fallback_location: account_management_root_path, notice: "Snoozed until #{l snooze.until.to_date, format: :long}."
    end

    def destroy
      scope = Snooze.where(user: Current.user)
      scope = scope.where(item_key: params[:key]) if params[:key].present?
      scope.delete_all
      redirect_back fallback_location: account_management_root_path, notice: params[:key].present? ? "Back on Today." : "Everything snoozed is back on Today."
    end
  end
end
