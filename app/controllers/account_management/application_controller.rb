module AccountManagement
  class ApplicationController < ::ApplicationController
    layout "application"

    before_action { head :not_found unless Runwell::Plugins.enabled?(:account_management) }
    before_action :require_member

    helper_method :current_member

    private
      # Account management works for the people it's switched on for (Settings > Account
      # management). Everyone else is told who can switch it on.
      def require_member
        return if current_member

        message = "Account management isn’t switched on for you. #{Current.user&.can?(:manage_settings) ? "Switch it on in Settings > Account management." : "Ask an owner to switch it on for you."}"
        redirect_to (Current.user&.can?(:manage_settings) ? account_management_settings_path : root_path), alert: message
      end

      def current_member = @current_member ||= Member.for(Current.user)

      def require_account_manager
        redirect_back fallback_location: account_management_root_path, alert: "Only someone who may manage accounts can do that." unless Current.user.can?(:manage_accounts)
      end

      def set_client = @client = ::Client.find(params[:client_id])

      # A client this member works with, for writes about it.
      def require_client_access
        return if current_member.all_clients? || current_member.client_ids.include?(@client.id) || Current.user.can?(:manage_accounts)

        redirect_back fallback_location: account_management_root_path, alert: "#{@client.name} isn’t one of your clients. Add it in My clients."
      end
  end
end
