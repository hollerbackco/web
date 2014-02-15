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
      data = [message.to_sync, message.membership.to_sync].as_json
      Hollerback::MQTT.delay.publish(channel, data)
    end

    def notify_push(message, person)
      membership = message.membership
      badge_count = person.unseen_memberships_count

      Hollerback::Push.delay.send(person.id, {
        alert: message.sender_name,
        badge: badge_count,
        sound: "default",
        content_available: true,
        data: {uuid: SecureRandom.uuid, conversation_id: membership.id}
      }.to_json)

      person.devices.android.each do |device|
        #res = ::GCMS.send_notification([device.token],
        #  data: nil,
        #  collapse_key: "new_message"
        #)
        res = Hollerback::GcmWrapper.send_notification([device.token],                     #tokens
                                                       Hollerback::GcmWrapper::TYPE::SYNC, #type
                                                       nil,                                #payload
                                                       collapse_key: "new_message")        #options

        puts res
      end
    end
  end
end
