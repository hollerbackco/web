require 'twilio-ruby'
require 'phone'

module Hollerback
  class SMS
    class << self
      def configure(sid, token, phone)
        @client = self.client(sid, token)
        @phone = phone
      end

      def send_message(recipient, msg, media_url=nil)
        data = {
          from: @phone,
          to: recipient,
          body: msg
        }
        if media_url
          data = data.merge(media_url: media_url)
        end

        @client.account.messages.create(data)
      end

      def client(sid,token)
        Twilio::REST::Client.new sid, token
      end
    end
  end
end
