# Who answers for a client, who covers while they're away, how often the client should hear
# from us, and whether it gets the weekly digest.
module AccountManagement
  class LeadsController < ApplicationController
    allow_staff
    before_action :require_account_manager, if: -> { params.key?(:user_id) }
    before_action :set_client
    before_action :require_client_access
    agent_tool :set_account_lead, on: :update, title: "Set a client's lead, backup, contact cadence or digest",
      description: "client_id from the path. Any of: user_id (who answers for the client; blank removes the lead; needs manage_accounts), backup_user_id (covers while the lead is away), contact_every_days (how often the client should hear from us; blank for the playbook's #{Playbook::CONTACT_EVERY}), digest_enabled (the weekly digest to the client). People must have account management switched on.",
      params: { user_id: "integer", backup_user_id: "integer", contact_every_days: "integer", digest_enabled: "boolean" }

    def update
      if params.key?(:user_id) && params[:user_id].blank?
        @client.account_lead&.destroy!
        @client.record_event!("account.lead_removed")
        return redirect_back fallback_location: client_path(@client), notice: "Nobody leads #{@client.name} now."
      end

      lead = @client.account_lead || @client.build_account_lead
      lead.user = member_user(params[:user_id]) if params.key?(:user_id)
      return redirect_back(fallback_location: client_path(@client), alert: "Choose who leads #{@client.name} first.") if lead.user.nil?

      lead.backup_user = params[:backup_user_id].present? ? member_user(params[:backup_user_id]) : nil if params.key?(:backup_user_id)
      lead.contact_every_days = params[:contact_every_days].presence if params.key?(:contact_every_days)
      lead.digest_enabled = ActiveModel::Type::Boolean.new.cast(params[:digest_enabled]) if params.key?(:digest_enabled)

      if lead.save
        @client.record_event!("account.lead_set", payload: { lead: lead.user.display_name, backup: lead.backup_user&.display_name }.compact) if lead.saved_change_to_user_id? || lead.saved_change_to_backup_user_id?
        redirect_back fallback_location: client_path(@client), notice: notice_for(lead)
      else
        redirect_back fallback_location: client_path(@client), alert: lead.errors.full_messages.to_sentence
      end
    end

    private
      def member_user(id) = ::User.where(id: Member.select(:user_id)).active.find_by(id: id)

      def notice_for(lead)
        return "#{lead.user.display_name} leads #{@client.name}." if lead.saved_change_to_user_id?
        return "#{lead.backup_user ? "#{lead.backup_user.display_name} backs up" : "No backup for"} #{@client.name}." if lead.saved_change_to_backup_user_id?
        return "#{@client.name} #{lead.digest_enabled? ? "gets" : "no longer gets"} the weekly digest." if lead.saved_change_to_digest_enabled?

        "#{@client.name} should hear from us every #{helpers.pluralize(lead.contact_every.in_days.round, "day")}."
      end
  end
end
