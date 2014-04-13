module Hollerback
  class NotifyRecipients
    attr_accessor :messages, :api_version

    def initialize(messages, opts={})
      @messages = messages
      @api_version = opts[:api_version]
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
      return if person.last_app_version.include?(';') #android doesn't use mqtt

      channel = "user/#{person.id}/sync"
      if(Gem::Version.new(person.last_app_version) > Gem::Version.new('1.5.0')) #need to do this based on app version of the person
        data = [message.to_sync_v1, message.membership.to_sync].as_json
      else
        data = [message.to_sync, message.membership.to_sync].as_json
      end

      Hollerback::MQTT.delay.publish(channel, data)
    end

    def notify_push(message, person)
      membership = message.membership
      badge_count = person.unseen_memberships_count

      if(message.message_type == Message::Type::TEXT)
        alert_msg = "#{message.sender_name}: #{message.content["text"]}"
      else
        alert_msg = "#{message.sender_name}"
      end


      Hollerback::Push.delay.send(person.id, {  #are we sending it to apple anyways?
        alert: alert_msg,
        badge: badge_count,
        sound: "default",
        content_available: true,
        data: {uuid: SecureRandom.uuid, conversation_id: membership.id}
      }.to_json)

      if(message.message_type == Message::Type::TEXT)
        person.devices.android.each do |device|
          res = Hollerback::GcmWrapper.send_notification([device.token],                     #tokens
                                                         Hollerback::GcmWrapper::TYPE::NOTIFICATION, #type
                                                         {:message => alert_msg},                                #payload
                                                         collapse_key: "new_message")        #options

          puts res
        end
      else
        person.devices.android.each do |device|
          res = Hollerback::GcmWrapper.send_notification([device.token],                     #tokens
                                                         Hollerback::GcmWrapper::TYPE::SYNC, #type
                                                         nil,                                #payload
                                                         collapse_key: "new_message")        #options

          puts res
        end
      end

    end
  end
end
