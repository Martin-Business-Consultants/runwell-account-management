# A client's promise, closed once we know how it went: kept (done), missed or dropped. Final once
# it's closed, as commitments were.
module AccountManagement
  class PromisesController < ApplicationController
    allow_staff
    agent_tool :resolve_client_promise, on: :update, title: "Close a client's promise",
      description: "How a promise the client made (a meeting's action item or a call's promise) went: done, missed or dropped. It's final.",
      params: { resolution: Promise::RESOLUTIONS }

    def update
      promise = Promise.find(params[:id])
      @client = promise.client
      return if require_client_access

      resolution = params[:resolution].presence_in(Promise::RESOLUTIONS) or
        return redirect_back(fallback_location: account_management_root_path, alert: "Say how it went: done, missed or dropped.")
      return redirect_back(fallback_location: account_management_root_path, alert: "That promise is already closed.") unless promise.open?

      promise.resolve!(resolution)
      redirect_back fallback_location: client_path(@client, tab: "plugin-account_management"), notice: "#{promise.description}: #{resolution}."
    end
  end
end
