require 'twilio-ruby'
require 'phone'

module Hollerback
  class SMS
    class << self
      def configure(sid, token, phone)
        @client = self.client(sid,token)
        @phone = phone
      end

      def send_message(recipient, msg)
        @client.account.sms.messages.create(
          from: @phone,
          to: recipient,
          body: msg
        )
      end

      def client(sid,token)
        Twilio::REST::Client.new sid, token
      end
    end
  end
end
