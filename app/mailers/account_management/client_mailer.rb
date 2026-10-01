module AccountManagement
  # A message to a client contact written in Runwell: a nudge about something we're waiting on,
  # or the weekly digest. Sent in the client's time zone, from the install's sender, with replies
  # going to whoever sent it.
  class ClientMailer < ::ApplicationMailer
    def letter
      @contact = params[:contact]
      @body = params[:body]
      reply_to = params[:reply_to]
      @contact.client.in_time_zone do
        mail to: @contact.email, subject: params[:subject], reply_to: reply_to.presence
      end
    end
  end
end
