# Who a contact is to us (decision-maker, day-to-day, billing, technical) and how they'd rather
# hear from us.
module AccountManagement
  class ContactProfilesController < ApplicationController
    allow_staff
    agent_tool :set_contact_role, on: :update, title: "Say who a client contact is to us",
      description: "roles: any of decision_maker, day_to_day, billing, technical. preferred_channel: email, phone, text, chat or meeting. Agendas, recaps, nudges and digests go to decision-makers and day-to-day contacts first.",
      params: { profile: { roles: ContactProfile::ROLES.keys, preferred_channel: ContactProfile::CHANNELS.keys } }

    before_action { @contact = ::Contact.find(params[:contact_id]); @client = @contact.client }
    before_action :require_client_access

    def update
      contact = @contact
      profile = ContactProfile.find_or_initialize_by(contact: contact)
      attributes = params.expect(profile: [ :preferred_channel, roles: [] ])
      profile.update!(roles: Array(attributes[:roles]), preferred_channel: attributes[:preferred_channel].presence)
      redirect_back fallback_location: client_path(contact.client, tab: "plugin-account_management"),
        notice: "#{contact.name}: #{profile.role_labels.to_sentence.presence || "no role"}#{", prefers #{profile.channel_label.downcase}" if profile.channel_label}."
    end
  end
end
