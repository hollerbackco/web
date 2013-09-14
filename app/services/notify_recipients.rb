module Hollerback
  class NotifyRecipients
    attr_accessor :messages

    def initialize(messages)
      @messages = messages
    end

    def run
      messages.each do |message|
        recipient = message.membership.user
        unless message.sender?
          notify_push message, recipient
        end
        notify_mqtt message, recipient
      end
    end

    private

    def notify_mqtt(message, person)
      MQTT::Client.connect(remote_host: '23.23.249.106', username: "UXiXTS1wiaZ7", password: "G4tkwWMOXa8V") do |c|
        data = [message.to_sync, message.membership.to_sync]
        c.publish("user/#{person.id}/sync", xtea.encrypt(data.to_json), false, 1)
      end
    end

    def xtea
      #key = "5410031E652142FEC303EB175CDDEE50"
      #key = "30313435453133303132353645463234"
      key = "8926AEC00DA47334F7A4F0689AA3E6B4"
      @xtea ||= ::Xtea.new(key, 64)
    end

    def notify_push(message, person)
      user = message.membership.user
      conversation = message.membership.conversation
      data = {
        conversation_id: message.membership.id,
        video_id: message.id,
        sender_name: message.sender_name
      }

      badge_count = person.unseen_memberships_count

      person.devices.ios.each do |device|
        APNS.send_notification(device.token, {
          alert: message.sender_name,
          badge: badge_count,
          sound: "default",
          other: {
            hb: data
          }
        })
      end

      person.devices.android.each do |device|
        ::GCMS.send_notification([device.token],
          data: data
        )
      end
    end
  end
end
