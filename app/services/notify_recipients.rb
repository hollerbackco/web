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
      channel = "user/#{person.id}/sync"
      data = [message.to_sync, message.membership.to_sync]
      Hollerback::MQTT.publish(channel, data)
    end

    def notify_push(message, person)
      user = message.membership.user
      conversation = message.membership.conversation
      badge_count = person.unseen_memberships_count

      person.devices.ios.each do |device|
        Hollerback::Push.send(device.token, {
          alert: message.sender_name,
          badge: badge_count,
          sound: "default",
          content_available: true
        })
      end

      data = [message.to_sync, message.membership.to_sync]
      person.devices.android.each do |device|
        ::GCMS.send_notification([device.token],
          data: data,
          collapse_key: "new_message"
        )
      end
    end
  end
end
