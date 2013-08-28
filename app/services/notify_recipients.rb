module Hollerback
  class NotifyRecipients
    attr_accessor :messages

    def initialize(messages)
      @messages = messages
    end

    def run
      messages.each do |message|
        recipient = message.membership.user
        notify_push message, recipient
        notify_mqtt message, recipient
      end
    end

    private

    def notify_mqtt(message, person)
      MQTT::Client.connect('23.23.249.106') do |c|
        c.publish("user/#{person.id}/video", message.as_json.to_json)
      end
    end

    def notify_push(message, person)
      user = message.membership.user
      conversation = message.membership.conversation
      data = {
        conversation_id: conversation.id,
        video_id: message.id,
        sender_name: user.name
      }

      badge_count = person.messages.unseen.count

      person.devices.ios.each do |device|
        APNS.send_notification(device.token, {
          alert: user.also_known_as(for: person),
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
