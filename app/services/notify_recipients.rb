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
      MQTT::Client.connect('23.23.249.106') do |c|
        c.publish("user/#{person.id}/video", message.to_sync.to_json)
      end
    end

    def notify_push(message, person)
      user = message.membership.user
      conversation = message.membership.conversation
      data = {
        conversation_id: membership.id,
        video_id: message.id,
        sender_name: message.sender_name
      }

      badge_count = person.messages.unseen.count

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
